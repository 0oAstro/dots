import { readFileSync } from "node:fs";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { getAgentDir, truncateHead, withFileMutationQueue, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import {
  FirecrawlClient,
  type AlexandriaResponse,
  type FirecrawlFormatRequest,
  type FirecrawlScrapeFormat,
  type FirecrawlScrapeResult,
  type FirecrawlSearchResult,
  type SearchCategory,
  type SearchSource,
} from "./client.js";
import { cleanFirecrawlHtml, extractFirecrawlContent, type ExtractedContent } from "./content.js";

const RECENCY_TO_TBS = {
  hour: "qdr:h",
  day: "qdr:d",
  week: "qdr:w",
  month: "qdr:m",
  year: "qdr:y",
} as const;

const SCRAPE_FORMATS = [
  "markdown",
  "summary",
  "html",
  "rawHtml",
  "links",
  "images",
  "screenshot",
  "branding",
  "audio",
] as const satisfies readonly FirecrawlScrapeFormat[];
const SEARCH_SOURCES = ["web", "news", "images", "alexandria"] as const satisfies readonly SearchSource[];
const SEARCH_CATEGORIES = ["github", "research", "pdf", "developer", "gov"] as const satisfies readonly SearchCategory[];

const DEFAULT_FETCH_MODEL = "openai-codex/gpt-5.3-codex-spark";
const DEFAULT_SEARCH_MAX_CHARS = 8192;
const DEFAULT_FETCH_MAX_CHARS = 20000;
const DEFAULT_MAP_MAX_CHARS = 12000;
const SEARCH_SNIPPET_MAX_CHARS = 900;
const SEARCH_CONTENT_MAX_CHARS = 2400;
const SETTINGS_KEY = "firecrawl-web";

function fetchModel(): string {
  const settingsPath = join(getAgentDir(), "settings.json");
  let settings: unknown;
  try {
    settings = JSON.parse(readFileSync(settingsPath, "utf8"));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return DEFAULT_FETCH_MODEL;
    throw new Error(`Could not read Firecrawl settings from ${settingsPath}: ${error instanceof Error ? error.message : String(error)}`);
  }
  if (!settings || typeof settings !== "object" || Array.isArray(settings)) return DEFAULT_FETCH_MODEL;
  const section = (settings as Record<string, unknown>)[SETTINGS_KEY];
  if (section === undefined) return DEFAULT_FETCH_MODEL;
  if (!section || typeof section !== "object" || Array.isArray(section)) {
    throw new Error(`${SETTINGS_KEY} in ${settingsPath} must be an object.`);
  }
  const configured = (section as Record<string, unknown>).fetchModel;
  if (configured === undefined) return DEFAULT_FETCH_MODEL;
  if (typeof configured !== "string" || !configured.includes("/") || !configured.trim()) {
    throw new Error(`${SETTINGS_KEY}.fetchModel in ${settingsPath} must be a provider/model string.`);
  }
  return configured.trim();
}

export async function boundedOutput(output: string, maximum: number, signal?: AbortSignal) {
  signal?.throwIfAborted();
  // Leave room for the continuation notice below Pi's own byte/line limits.
  const preview = truncateHead(output, { maxBytes: 48_000, maxLines: 1900 });
  if (output.length <= maximum && !preview.truncated) return { text: output, fullOutputPath: undefined };
  const directory = await mkdtemp(join(tmpdir(), "pi-firecrawl-"));
  const fullOutputPath = join(directory, "output.txt");
  try {
    signal?.throwIfAborted();
    await withFileMutationQueue(fullOutputPath, () => writeFile(fullOutputPath, output, { encoding: "utf8", mode: 0o600, signal }));
    signal?.throwIfAborted();
  } catch (error) {
    await rm(directory, { recursive: true, force: true });
    throw error;
  }
  const marker = `\n\n[Output truncated; ${output.length} chars total. Full output: ${fullOutputPath}. Use read with offset/limit to continue.]`;
  const head = preview.content.slice(0, Math.max(0, maximum - marker.length)).replace(/[\uD800-\uDBFF]$/, "");
  return { text: head + marker, fullOutputPath };
}

function compactSearchText(value: string, maximum: number): string {
  const cleaned = value.replace(/!\[[^\]]*\]\([^)]*\)/g, "").replace(/\s+/g, " ").trim();
  if (cleaned.length <= maximum) return cleaned;
  const marker = ` ... [snippet truncated, ${cleaned.length} chars total]`;
  return `${cleaned.slice(0, Math.max(0, maximum - marker.length))}${marker}`;
}

function presentSearch(
  result: FirecrawlSearchResult,
  query: string,
  includeContent: boolean,
): string {
  const seenUrls = new Set<string>();
  const web = result.web.filter((item) => {
    const key = item.url.trim().replace(/\/$/, "");
    if (!key || seenUrls.has(key)) return false;
    seenUrls.add(key);
    return true;
  });
  const sections = web.map((item, index) => {
    const lines = [`Result ${index + 1}: ${item.title?.trim() || "Untitled"}`, `URL: ${item.url}`];
    if (item.description?.trim()) lines.push(`Snippet: ${compactSearchText(item.description, SEARCH_SNIPPET_MAX_CHARS)}`);
    if (item.category?.trim()) lines.push(`Category: ${item.category.trim()}`);
    if (includeContent) {
      const markdown = item.markdown?.trim();
      lines.push(markdown
        ? `Content:\n${markdown.slice(0, SEARCH_CONTENT_MAX_CHARS)}${markdown.length > SEARCH_CONTENT_MAX_CHARS ? "\n[Content preview truncated; use web_fetch for the complete page.]" : ""}`
        : "Page content unavailable; use web_fetch on this URL if needed.");
    }
    return lines.join("\n");
  });
  sections.push(...result.news.map((item, index) => [
    `News ${index + 1}: ${item.title?.trim() || "Untitled"}${item.date ? ` (${item.date})` : ""}`,
    `URL: ${item.url}`,
    ...(item.snippet?.trim() ? [`Snippet: ${compactSearchText(item.snippet, SEARCH_SNIPPET_MAX_CHARS)}`] : []),
  ].join("\n")));
  sections.push(...result.images.map((item, index) => [
    `Image ${index + 1}: ${item.title?.trim() || "Untitled"}${item.imageWidth && item.imageHeight ? ` (${item.imageWidth}x${item.imageHeight})` : ""}`,
    `Image URL: ${item.imageUrl}`,
    ...(item.url ? [`Page: ${item.url}`] : []),
  ].join("\n")));
  sections.push(...result.tools.map((tool, index) => [
    `Tool ${index + 1}: {provider: "${tool.provider}", capability: "${tool.capability}"}${tool.creditsCost === undefined ? "" : ` (${tool.creditsCost} credits${tool.perRecord ? " per record" : ""})`}`,
    ...(tool.description?.trim() ? [compactSearchText(tool.description, SEARCH_SNIPPET_MAX_CHARS)] : []),
    ...(tool.requiresOneOf ? [`Requires one of: ${JSON.stringify(tool.requiresOneOf)}`] : []),
  ].join("\n")));
  if (result.tools.length > 0) {
    sections.push('Inspect a tool\'s options with web_fetch({ alexandria: { provider: "firecrawl", capability: "find-tools", options: { providers: [provider], capabilities: [capability], expand: ["options", "examples"] } } }), then run it with web_fetch({ alexandria: { provider, capability, options } }).');
  }
  const body = sections.length > 0 ? sections.join("\n\n---\n\n") : `No results returned for query: ${query}`;
  return `Results for query "${query}":\n\n${body}${result.warning ? `\n\nWarning: ${compactSearchText(result.warning, 600)}` : ""}`;
}

function presentAlexandria(response: AlexandriaResponse): string {
  return response.results.map((result) => result.kind === "ok"
    ? `${result.provider}/${result.capability} (${result.creditsCost} credits):\n${JSON.stringify(result.data, null, 2)}`
    : `${result.provider}/${result.capability} failed:\n${JSON.stringify(result.error, null, 2)}`).join("\n\n");
}

function failOnSourceError(result: FirecrawlScrapeResult, url: string): void {
  if ((result.metadata.statusCode ?? 0) < 400) return;
  throw new Error(`Page fetch failed (HTTP ${result.metadata.statusCode}): ${result.metadata.error ?? result.metadata.title ?? "source returned an error"}. URL: ${url}`);
}

function scrapeHeader(result: FirecrawlScrapeResult, url: string): string {
  const metadata = result.metadata;
  const cache = metadata.cacheState ?? "unknown";
  const cachedAt = metadata.cachedAt ? `; cachedAt=${metadata.cachedAt}` : "";
  const timestamp = Date.parse(metadata.cachedAt ?? "");
  const age = Number.isFinite(timestamp) ? `; age=${Math.max(0, Math.floor((Date.now() - timestamp) / 1000))}s` : "";
  return [
    metadata.title ? `Page: ${compactSearchText(metadata.title, 300)}` : undefined,
    `URL: ${url}`,
    `HTTP: ${metadata.statusCode ?? "unknown"}; cache=${cache}${cachedAt}${age}`,
    result.warning ? `Warning: ${compactSearchText(result.warning, 600)}` : undefined,
  ].filter((line) => line !== undefined).join("\n");
}

const BINARY_FORMATS = new Set<FirecrawlScrapeFormat>(["screenshot", "audio"]);

export function presentScrape(
  result: FirecrawlScrapeResult,
  url: string,
  formats: readonly FirecrawlScrapeFormat[],
  focus?: { extracted?: ExtractedContent },
): string {
  const focusNotice = focus
    ? !focus.extracted
      ? "Focused extraction unavailable; returned cleaned page content."
      : focus.extracted.inputTruncated
        ? "Warning: Focused extraction input was limited to 120,000 characters; the model did not see the entire page. Fetch without instruction for complete source content."
        : "Focused extraction."
    : undefined;
  const lines = [focusNotice, scrapeHeader(result, url)].filter((line): line is string => line !== undefined);
  if (focus?.extracted) return [...lines, focus.extracted.text].join("\n\n");
  const headerCount = lines.length;
  for (const format of formats) {
    const value = result[format as keyof FirecrawlScrapeResult];
    if (typeof value === "string" && value.trim()) {
      if (BINARY_FORMATS.has(format) && !/^https?:\/\//i.test(value)) {
        lines.push(`${format}: [binary payload omitted from text output; ${value.length} chars]`);
        continue;
      }
      const text = value.trim();
      if (text) lines.push(format === "markdown" ? text : `${format}:\n${text}`);
    } else if (Array.isArray(value) && value.length > 0) {
      lines.push(`${format} (${value.length}):\n${value.join("\n")}`);
    } else if (format === "branding" && value && typeof value === "object") {
      lines.push(`branding:\n${JSON.stringify(value, null, 2)}`);
    }
  }
  if (lines.length === headerCount) lines.push("No content returned for the requested formats.");
  return lines.join("\n\n");
}

function expandedToolText(result: { content?: readonly unknown[] }, expanded: boolean): string | undefined {
  if (!expanded) return undefined;
  const text = (result.content ?? []).flatMap((item) => {
    if (!item || typeof item !== "object") return [];
    const block = item as { type?: unknown; text?: unknown };
    return block.type === "text" && typeof block.text === "string" ? [block.text] : [];
  }).join("\n");
  return text || "No output.";
}

export default function firecrawlWeb(pi: ExtensionAPI) {
  function resolveApiKey(): string {
    const apiKey = process.env.FIRECRAWL_API_KEY?.trim();
    if (!apiKey) throw new Error("Firecrawl is not configured. Set FIRECRAWL_API_KEY before starting Pi.");
    return apiKey;
  }

  function client(): FirecrawlClient {
    return new FirecrawlClient(resolveApiKey());
  }

  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search through Firecrawl. Returns compact titles, URLs, and snippets. sources adds news, images, or free Alexandria data-tool discovery; includeContent adds page Markdown (extra credits). Output defaults to 8,192 characters, capped at 20,000; truncated output is saved for read.",
    promptGuidelines: ["Prefer native web tools for public-web research; use MCP only for unsupported formats or advanced controls."],
    promptSnippet: "Search the live web through Firecrawl",
    parameters: Type.Object({
      query: Type.String({ description: "Concise web search query." }),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 20, description: "Maximum results; default 5." })),
      includeDomains: Type.Optional(Type.Array(Type.String(), { maxItems: 20, description: "Only return these domains." })),
      excludeDomains: Type.Optional(Type.Array(Type.String(), { maxItems: 20, description: "Exclude these domains." })),
      recency: Type.Optional(StringEnum(["hour", "day", "week", "month", "year"] as const)),
      sources: Type.Optional(Type.Array(StringEnum(SEARCH_SOURCES), { minItems: 1, maxItems: 4, description: "Default [\"web\"]. \"alexandria\" alone returns structured data tools (free) to run with web_fetch." })),
      categories: Type.Optional(Type.Array(StringEnum(SEARCH_CATEGORIES), { minItems: 1, maxItems: 5, description: "Restrict web results to these site categories." })),
      highlights: Type.Optional(Type.Boolean({ description: "Query-relevant page passages instead of short snippets; slower. Default false." })),
      includeContent: Type.Optional(Type.Boolean({ description: "Request page Markdown with search results; costs extra credits. Default false. Content previews preserve code formatting." })),
      maxAge: Type.Optional(Type.Integer({ minimum: 0, description: "Maximum page cache age in milliseconds; 0 forces fresh scraping. Requires includeContent=true." })),
      maxChars: Type.Optional(Type.Integer({ minimum: 1000, maximum: 20000, description: "Maximum returned characters; default 8192." })),
    }),
    async execute(_toolCallId, params, signal, onUpdate) {
      if (params.includeDomains && params.excludeDomains) {
        throw new Error("includeDomains and excludeDomains cannot be used together.");
      }
      if (params.maxAge !== undefined && !params.includeContent) throw new Error("maxAge requires includeContent=true; it controls scraped pages, not search-index freshness.");
      const query = params.query.trim();
      if (!query) throw new Error("Search query cannot be blank.");
      onUpdate?.({ content: [{ type: "text", text: `Searching for: ${query}` }], details: {} });
      const result = await client().search({
        query,
        limit: params.limit ?? 5,
        sources: params.sources ?? ["web"],
        categories: params.categories,
        highlights: params.highlights ?? false,
        toolDetail: params.sources?.includes("alexandria") ? "summary" : undefined,
        includeDomains: params.includeDomains,
        excludeDomains: params.excludeDomains,
        tbs: params.recency ? RECENCY_TO_TBS[params.recency] : undefined,
        scrapeOptions: params.includeContent ? { formats: ["markdown"], onlyMainContent: true, maxAge: params.maxAge } : undefined,
      }, signal);
      const output = await boundedOutput(presentSearch(result, query, params.includeContent ?? false), params.maxChars ?? DEFAULT_SEARCH_MAX_CHARS, signal);
      return {
        content: [{ type: "text", text: output.text }],
        details: {
          provider: "firecrawl",
          query,
          includeContent: params.includeContent ?? false,
          resultCount: result.web.length + result.news.length + result.images.length + result.tools.length,
          results: result.web.map(({ markdown: _markdown, ...item }) => item),
          news: result.news,
          images: result.images,
          tools: result.tools,
          fullOutputPath: output.fullOutputPath,
          warning: result.warning,
          creditsUsed: result.creditsUsed,
        },
      };
    },
    renderCall(args, theme) {
      return new Text(`${theme.fg("toolTitle", theme.bold("WebSearch "))}${theme.fg("accent", `"${args.query}"`)}`, 0, 0);
    },
    renderResult(result, { isPartial, expanded }, theme, ctx) {
      if (isPartial) return new Text(theme.fg("warning", "Searching..."), 0, 0);
      const expandedText = expandedToolText(result, expanded || ctx.isError);
      if (expandedText !== undefined) return new Text(theme.fg("toolOutput", expandedText), 0, 0);
      const details = result.details as { resultCount?: number } | undefined;
      const count = details?.resultCount ?? 0;
      return new Text(theme.fg("success", `${count} result${count === 1 ? "" : "s"}`), 0, 0);
    },
  });

  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description:
      "Fetch a URL through Firecrawl with HTTP/cache metadata and cleaned content, or run an Alexandria data tool. instruction asks Firecrawl to answer from the page (5 credits); with schema it returns JSON. maxAge=0 forces a fresh fetch. Output is capped at 40,000 characters; complete truncated output is saved for read with offset/limit.",
    promptSnippet: "Fetch or focus-extract a web page through Firecrawl",
    parameters: Type.Object({
      url: Type.Optional(Type.String({ description: "HTTP(S) page URL. Required unless alexandria is given." })),
      alexandria: Type.Optional(Type.Object({
        provider: Type.String(),
        capability: Type.String(),
        options: Type.Optional(Type.Record(Type.String(), Type.Unknown())),
      }, { description: "Run a catalogued data tool instead of fetching a URL; charged at the tool's listed price. Discover with web_search sources [\"alexandria\"]. provider \"firecrawl\", capability \"find-tools\" is free and returns contracts." })),
      formats: Type.Optional(Type.Array(StringEnum(SCRAPE_FORMATS), { minItems: 1, maxItems: 4, description: "Formats; default markdown." })),
      onlyMainContent: Type.Optional(Type.Boolean({ description: "Exclude navigation and boilerplate; default true." })),
      instruction: Type.Optional(Type.String({ description: "Question or extraction instruction answered from the page. Falls back to firecrawl-web.fetchModel on cleaned Markdown." })),
      schema: Type.Optional(Type.Record(Type.String(), Type.Unknown(), { description: "JSON Schema for structured extraction; instruction becomes its prompt." })),
      maxAge: Type.Optional(Type.Integer({ minimum: 0, description: "Maximum Firecrawl cache age in milliseconds; 0 forces a fresh fetch. Omit to use Firecrawl's default cache policy." })),
      maxChars: Type.Optional(Type.Integer({ minimum: 1000, maximum: 40000, description: "Maximum returned characters; default 20,000 raw or 12,000 focused." })),
    }),
    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      if (params.alexandria) {
        if (params.url) throw new Error("Pass either url or alexandria, not both.");
        const call = params.alexandria;
        onUpdate?.({ content: [{ type: "text", text: `Running: ${call.provider}/${call.capability}` }], details: {} });
        const response = await client().alexandria(call, signal);
        const output = await boundedOutput(presentAlexandria(response), params.maxChars ?? DEFAULT_FETCH_MAX_CHARS, signal);
        return {
          content: [{ type: "text", text: output.text }],
          details: { provider: "firecrawl", alexandria: call, creditsCost: response.creditsCost, fullOutputPath: output.fullOutputPath },
        };
      }
      const url = params.url?.trim();
      if (!url) throw new Error("web_fetch needs url or alexandria.");
      const formats = (params.formats ?? ["markdown"]) as FirecrawlScrapeFormat[];
      const instruction = params.instruction?.trim();
      if (params.schema && !instruction) throw new Error("schema needs an instruction describing what to extract.");
      const outputFormats: FirecrawlScrapeFormat[] = instruction && !formats.includes("markdown") ? ["markdown", ...formats] : formats;
      const requestFormats = [...new Set([
        ...formats, ...outputFormats,
        ...(outputFormats.includes("markdown") ? ["html"] : []),
      ])] as FirecrawlScrapeFormat[];
      const maxOutput = params.maxChars ?? (instruction ? 12000 : DEFAULT_FETCH_MAX_CHARS);
      onUpdate?.({ content: [{ type: "text", text: `Fetching: ${url}` }], details: {} });
      if (instruction) {
        const answerFormat: FirecrawlFormatRequest = params.schema
          ? { type: "json", schema: params.schema, prompt: instruction }
          : { type: "question", question: instruction };
        const answered = await client().scrape({ url, formats: [answerFormat], onlyMainContent: params.onlyMainContent ?? true, maxAge: params.maxAge }, signal);
        failOnSourceError(answered, url);
        const answer = params.schema ? (answered.json === undefined ? undefined : JSON.stringify(answered.json, null, 2)) : answered.answer?.trim();
        if (answer) {
          const output = await boundedOutput([`Answered by Firecrawl.`, scrapeHeader(answered, url), answer].join("\n\n"), maxOutput, signal);
          return {
            content: [{ type: "text", text: output.text }],
            details: { provider: "firecrawl", url, metadata: answered.metadata, warning: answered.warning, focused: true, answeredBy: "firecrawl", fullOutputPath: output.fullOutputPath },
          };
        }
      }
      const result = await client().scrape({
        url,
        formats: requestFormats,
        onlyMainContent: params.onlyMainContent ?? true,
        maxAge: params.maxAge,
      }, signal);
      failOnSourceError(result, url);
      const defuddledMarkdown = outputFormats.includes("markdown") && params.onlyMainContent !== false && result.html
        ? await cleanFirecrawlHtml(result.html, url) : undefined;
      signal?.throwIfAborted();
      const cleanedResult = defuddledMarkdown ? { ...result, markdown: defuddledMarkdown } : result;
      const cleaner = defuddledMarkdown ? "defuddle" : "firecrawl";
      const extracted = instruction && cleanedResult.markdown ? await extractFirecrawlContent({
        registry: ctx.modelRegistry,
        url,
        markdown: cleanedResult.markdown,
        instruction,
        model: fetchModel(),
        maxOutput,
        signal,
      }) : undefined;
      const body = presentScrape(cleanedResult, url, outputFormats, instruction ? { extracted } : undefined);
      const output = await boundedOutput(body, maxOutput, signal);
      return {
        content: [{ type: "text", text: output.text }],
        details: {
          provider: "firecrawl",
          cleaner,
          url,
          formats: outputFormats,
          metadata: result.metadata,
          warning: result.warning,
          focused: Boolean(extracted),
          fullOutputPath: output.fullOutputPath,
          extractionInputTruncated: extracted?.inputTruncated,
          extractionModel: extracted?.model,
          answeredBy: extracted ? "model" : undefined,
        },
        usage: extracted?.usage,
      };
    },
    renderCall(args, theme) {
      const suffix = args.instruction ? theme.fg("dim", " focused") : "";
      const target = args.alexandria ? `${args.alexandria.provider}/${args.alexandria.capability}` : args.url ?? "";
      return new Text(`${theme.fg("toolTitle", theme.bold("WebFetch "))}${theme.fg("accent", target)}${suffix}`, 0, 0);
    },
    renderResult(result, { isPartial, expanded }, theme, ctx) {
      if (isPartial) return new Text(theme.fg("warning", "Fetching..."), 0, 0);
      const expandedText = expandedToolText(result, expanded || ctx.isError);
      if (expandedText !== undefined) return new Text(theme.fg("toolOutput", expandedText), 0, 0);
      const details = result.details as { focused?: boolean; metadata?: { statusCode?: number } } | undefined;
      const status = details?.metadata?.statusCode ? `HTTP ${details.metadata.statusCode}` : "fetched";
      return new Text(theme.fg("success", details?.focused ? `${status}, focused extraction` : status), 0, 0);
    },
  });

  pi.registerTool({
    name: "web_map",
    label: "Web Map",
    description: "Discover URLs on a site through Firecrawl. Returns a compact link list, capped at 20,000 characters; complete truncated output is saved for read.",
    promptSnippet: "Discover URLs on a site through Firecrawl",
    parameters: Type.Object({
      url: Type.String({ description: "Site URL." }),
      search: Type.Optional(Type.String({ description: "Optional term used to rank or filter discovered URLs." })),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 500, description: "Maximum links; default 100." })),
      maxChars: Type.Optional(Type.Integer({ minimum: 1000, maximum: 20000, description: "Maximum returned characters; default 12,000." })),
    }),
    async execute(_toolCallId, params, signal, onUpdate) {
      onUpdate?.({ content: [{ type: "text", text: `Mapping: ${params.url}` }], details: {} });
      const result = await client().map({
        url: params.url,
        search: params.search,
        limit: params.limit ?? 100,
      }, signal);
      const body = result.links.map((link, index) => {
        const label = link.title?.trim() ? `${index + 1}. ${link.title.trim()}\n` : `${index + 1}. `;
        return `${label}${link.url}${link.description?.trim() ? `\n${compactSearchText(link.description, 600)}` : ""}`;
      }).join("\n\n");
      const output = await boundedOutput(body || `No URLs discovered for ${params.url}`, params.maxChars ?? DEFAULT_MAP_MAX_CHARS, signal);
      return {
        content: [{ type: "text", text: output.text }],
        details: { provider: "firecrawl", url: params.url, linkCount: result.links.length, links: result.links, fullOutputPath: output.fullOutputPath },
      };
    },
    renderCall(args, theme) {
      return new Text(`${theme.fg("toolTitle", theme.bold("WebMap "))}${theme.fg("accent", args.url)}`, 0, 0);
    },
    renderResult(result, { isPartial, expanded }, theme, ctx) {
      if (isPartial) return new Text(theme.fg("warning", "Mapping..."), 0, 0);
      const expandedText = expandedToolText(result, expanded || ctx.isError);
      if (expandedText !== undefined) return new Text(theme.fg("toolOutput", expandedText), 0, 0);
      const details = result.details as { linkCount?: number } | undefined;
      const count = details?.linkCount ?? 0;
      return new Text(theme.fg("success", `${count} link${count === 1 ? "" : "s"}`), 0, 0);
    },
  });

  pi.registerCommand("firecrawl", {
    description: "Show the Firecrawl web integration status",
    handler: async (_args, ctx) => {
      try {
        resolveApiKey();
        ctx.ui.notify(`Firecrawl ready: search, fetch, and map; fetch model: ${fetchModel()}`, "info");
      } catch (error) {
        ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
      }
    },
  });
}
