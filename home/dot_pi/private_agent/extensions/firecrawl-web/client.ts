export const FIRECRAWL_V2_BASE_URL = "https://api.firecrawl.dev/v2";

export type FirecrawlScrapeFormat =
  | "markdown"
  | "summary"
  | "html"
  | "rawHtml"
  | "links"
  | "images"
  | "screenshot"
  | "branding"
  | "audio"
  | "highlights";

export interface FirecrawlWebResult {
  url: string;
  title?: string;
  description?: string;
  markdown?: string;
  category?: string;
}

export interface FirecrawlSearchResult {
  web: FirecrawlWebResult[];
  warning?: string;
  id?: string;
  creditsUsed?: number;
}

export interface FirecrawlScrapeMetadata {
  title?: string;
  description?: string;
  language?: string;
  sourceURL?: string;
  url?: string;
  statusCode?: number;
  contentType?: string;
  error?: string;
  scrapeId?: string;
  cacheState?: string;
  cachedAt?: string;
  creditsUsed?: number;
  [key: string]: unknown;
}

export interface FirecrawlScrapeResult {
  markdown?: string;
  summary?: string;
  html?: string;
  rawHtml?: string;
  screenshot?: string;
  audio?: string;
  highlights?: string[];
  links?: string[];
  images?: string[];
  branding?: Record<string, unknown>;
  metadata: FirecrawlScrapeMetadata;
  warning?: string;
}

export interface FirecrawlMapLink {
  url: string;
  title?: string;
  description?: string;
}

export interface FirecrawlMapResult {
  links: FirecrawlMapLink[];
}

export interface SearchRequest {
  query: string;
  limit?: number;
  sources: ["web"];
  includeDomains?: string[];
  excludeDomains?: string[];
  tbs?: string;
  scrapeOptions?: { formats: ["markdown"]; onlyMainContent: boolean; maxAge?: number };
}

export interface ScrapeRequest {
  url: string;
  formats: FirecrawlScrapeFormat[];
  onlyMainContent: boolean;
  maxAge?: number;
}

export interface MapRequest {
  url: string;
  search?: string;
  limit?: number;
}

export class FirecrawlApiError extends Error {
  readonly status: number;
  readonly code?: string;

  constructor(message: string, status: number, code?: string) {
    super(message);
    this.name = "FirecrawlApiError";
    this.status = status;
    this.code = code;
  }
}

export class FirecrawlTransportError extends Error {
  constructor() {
    super("Firecrawl transport request failed.");
    this.name = "FirecrawlTransportError";
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function stringValue(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function numberValue(value: unknown): number | undefined {
  return typeof value === "number" ? value : undefined;
}

function stringArray(value: unknown): string[] | undefined {
  return Array.isArray(value) && value.every((item) => typeof item === "string")
    ? value
    : undefined;
}

function requireRecord(value: unknown, label: string): Record<string, unknown> {
  if (!isRecord(value)) throw new Error(`Firecrawl returned an invalid ${label} response.`);
  return value;
}

function requireSuccess(payload: unknown, label: string): Record<string, unknown> {
  const record = requireRecord(payload, label);
  if (record.success !== true) {
    throw new FirecrawlApiError(
      `Firecrawl ${label} failed: ${stringValue(record.error) ?? "unsuccessful response"}.`,
      numberValue(record.statusCode) ?? 200,
      stringValue(record.code),
    );
  }
  return record;
}

function parseWebResults(value: unknown): FirecrawlWebResult[] {
  if (!Array.isArray(value)) return [];
  return value.flatMap((item) => {
    if (!isRecord(item) || typeof item.url !== "string") return [];
    return [{
      url: item.url,
      title: stringValue(item.title),
      description: stringValue(item.description),
      markdown: stringValue(item.markdown),
      category: stringValue(item.category),
    }];
  });
}

function responseWarning(...records: Record<string, unknown>[]): string | undefined {
  const warnings = records.flatMap((record) => [stringValue(record.warning), ...(stringArray(record.warnings) ?? [])]);
  return [...new Set(warnings.filter((value): value is string => Boolean(value)))].join("; ") || undefined;
}

function parseSearchResponse(payload: unknown): FirecrawlSearchResult {
  const response = requireSuccess(payload, "search");
  const data = requireRecord(response.data, "search data");
  return {
    web: parseWebResults(data.web),
    warning: responseWarning(response, data),
    id: stringValue(response.id),
    creditsUsed: numberValue(response.creditsUsed),
  };
}

function parseScrapeResponse(payload: unknown): FirecrawlScrapeResult {
  const response = requireSuccess(payload, "scrape");
  const data = requireRecord(response.data, "scrape data");
  return {
    markdown: stringValue(data.markdown),
    summary: stringValue(data.summary),
    html: stringValue(data.html),
    rawHtml: stringValue(data.rawHtml),
    screenshot: stringValue(data.screenshot),
    audio: stringValue(data.audio),
    highlights: stringArray(data.highlights),
    links: stringArray(data.links),
    images: stringArray(data.images),
    branding: isRecord(data.branding) ? data.branding : undefined,
    metadata: isRecord(data.metadata) ? data.metadata : {},
    warning: responseWarning(response, data),
  };
}

function parseMapResponse(payload: unknown): FirecrawlMapResult {
  const response = requireSuccess(payload, "map");
  const links: FirecrawlMapLink[] = [];
  if (Array.isArray(response.links)) {
    for (const item of response.links) {
      if (!isRecord(item) || typeof item.url !== "string") continue;
      links.push({
        url: item.url,
        title: stringValue(item.title),
        description: stringValue(item.description),
      });
    }
  }
  return { links };
}

export class FirecrawlClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(apiKey: string, baseUrl = FIRECRAWL_V2_BASE_URL) {
    if (!apiKey.trim()) throw new Error("Firecrawl API key is required.");
    this.apiKey = apiKey.trim();
    this.baseUrl = baseUrl.replace(/\/+$/, "");
  }

  async search(options: SearchRequest, signal?: AbortSignal): Promise<FirecrawlSearchResult> {
    return parseSearchResponse(await this.request("search", options, signal));
  }

  async scrape(options: ScrapeRequest, signal?: AbortSignal): Promise<FirecrawlScrapeResult> {
    return parseScrapeResponse(await this.request("scrape", options, signal));
  }

  async map(options: MapRequest, signal?: AbortSignal): Promise<FirecrawlMapResult> {
    return parseMapResponse(await this.request("map", options, signal));
  }

  private async request(endpoint: string, body: object, signal?: AbortSignal): Promise<unknown> {
    signal?.throwIfAborted();
    let response: Response;
    try {
      response = await fetch(`${this.baseUrl}/${endpoint}`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
        signal,
      });
    } catch (error) {
      if (signal?.aborted || (error instanceof DOMException && error.name === "AbortError")) throw error;
      throw new FirecrawlTransportError();
    }

    if (!response.ok) {
      const payload = await this.readJson(response, signal);
      throw new FirecrawlApiError(
        `Firecrawl HTTP ${response.status}: ${isRecord(payload) ? stringValue(payload.error) ?? "request failed" : "request failed"}.`,
        response.status,
        isRecord(payload) ? stringValue(payload.code) : undefined,
      );
    }
    return this.readJson(response, signal);
  }

  private async readJson(response: Response, signal?: AbortSignal): Promise<unknown> {
    try {
      return await response.json();
    } catch {
      signal?.throwIfAborted();
      throw new FirecrawlApiError(`Firecrawl returned a non-JSON response (HTTP ${response.status}).`, response.status);
    }
  }
}
