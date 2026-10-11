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
  | "audio";

export type FirecrawlFormatRequest =
  | FirecrawlScrapeFormat
  | { type: "question"; question: string }
  | { type: "json"; schema: Record<string, unknown>; prompt?: string };

export type SearchSource = "web" | "news" | "images" | "alexandria";
export type SearchCategory = "github" | "research" | "pdf" | "developer" | "gov";

export interface FirecrawlWebResult {
  url: string;
  title?: string;
  description?: string;
  markdown?: string;
  category?: string;
}

export interface FirecrawlNewsResult {
  url: string;
  title?: string;
  snippet?: string;
  date?: string;
}

export interface FirecrawlImageResult {
  url?: string;
  imageUrl: string;
  title?: string;
  imageWidth?: number;
  imageHeight?: number;
}

export interface AlexandriaCall {
  provider: string;
  capability: string;
  options?: Record<string, unknown>;
}

export interface FirecrawlToolContract {
  provider: string;
  capability: string;
  description?: string;
  creditsCost?: number;
  perRecord?: boolean;
  requiresOneOf?: unknown;
}

export interface FirecrawlSearchResult {
  web: FirecrawlWebResult[];
  news: FirecrawlNewsResult[];
  images: FirecrawlImageResult[];
  tools: FirecrawlToolContract[];
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
  links?: string[];
  images?: string[];
  branding?: Record<string, unknown>;
  answer?: string;
  json?: unknown;
  metadata: FirecrawlScrapeMetadata;
  warning?: string;
}

export type AlexandriaResult =
  | { kind: "ok"; provider: string; capability: string; creditsCost: number; data: unknown }
  | { kind: "error"; provider: string; capability: string; error: unknown };

export interface AlexandriaResponse {
  results: AlexandriaResult[];
  creditsCost?: number;
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
  sources: SearchSource[];
  categories?: SearchCategory[];
  includeDomains?: string[];
  excludeDomains?: string[];
  tbs?: string;
  country?: string;
  location?: string;
  highlights: boolean;
  toolDetail?: "compact" | "summary" | "full";
  scrapeOptions?: { formats: ["markdown"]; onlyMainContent: boolean; maxAge?: number };
}

export interface ScrapeRequest {
  url: string;
  formats: FirecrawlFormatRequest[];
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

// Free plans allow ~12 requests/minute; codemode fan-out hits that quickly.
const MAX_RATE_LIMIT_RETRIES = 3;
const MAX_RATE_LIMIT_WAIT_SECONDS = 30;

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

function records(value: unknown): Record<string, unknown>[] {
  return Array.isArray(value) ? value.filter(isRecord) : [];
}

function parseWebResults(value: unknown): FirecrawlWebResult[] {
  return records(value).flatMap((item) => typeof item.url !== "string" ? [] : [{
    url: item.url,
    title: stringValue(item.title),
    description: stringValue(item.description),
    markdown: stringValue(item.markdown),
    category: stringValue(item.category),
  }]);
}

function parseNewsResults(value: unknown): FirecrawlNewsResult[] {
  return records(value).flatMap((item) => typeof item.url !== "string" ? [] : [{
    url: item.url,
    title: stringValue(item.title),
    snippet: stringValue(item.snippet),
    date: stringValue(item.date),
  }]);
}

function parseImageResults(value: unknown): FirecrawlImageResult[] {
  return records(value).flatMap((item) => typeof item.imageUrl !== "string" ? [] : [{
    imageUrl: item.imageUrl,
    url: stringValue(item.url),
    title: stringValue(item.title),
    imageWidth: numberValue(item.imageWidth),
    imageHeight: numberValue(item.imageHeight),
  }]);
}

function parseToolContracts(value: unknown): FirecrawlToolContract[] {
  return records(value).flatMap((item) => {
    if (typeof item.provider !== "string" || typeof item.capability !== "string") return [];
    return [{
      provider: item.provider,
      capability: item.capability,
      description: stringValue(item.description),
      creditsCost: numberValue(item.creditsCost),
      perRecord: typeof item.perRecord === "boolean" ? item.perRecord : undefined,
      requiresOneOf: item.requiresOneOf,
    }];
  });
}

function responseWarning(...items: Record<string, unknown>[]): string | undefined {
  const warnings = items.flatMap((item) => [stringValue(item.warning), ...(stringArray(item.warnings) ?? [])]);
  return [...new Set(warnings.filter((value): value is string => Boolean(value)))].join("; ") || undefined;
}

function parseSearchResponse(payload: unknown): FirecrawlSearchResult {
  const response = requireSuccess(payload, "search");
  const data = requireRecord(response.data, "search data");
  return {
    web: parseWebResults(data.web),
    news: parseNewsResults(data.news),
    images: parseImageResults(data.images),
    tools: parseToolContracts(data.tools),
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
    links: stringArray(data.links),
    images: stringArray(data.images),
    branding: isRecord(data.branding) ? data.branding : undefined,
    answer: stringValue(data.answer),
    json: data.json,
    metadata: isRecord(data.metadata) ? data.metadata : {},
    warning: responseWarning(response, data),
  };
}

function parseAlexandriaResponse(payload: unknown): AlexandriaResponse {
  const response = requireSuccess(payload, "alexandria");
  const data = requireRecord(response.data, "alexandria data");
  return {
    creditsCost: numberValue(data.creditsCost),
    results: records(data.alexandria).map((item) => {
      const provider = stringValue(item.provider) ?? "unknown";
      const capability = stringValue(item.capability) ?? "unknown";
      return item.error !== undefined
        ? { kind: "error", provider, capability, error: item.error }
        : { kind: "ok", provider, capability, creditsCost: numberValue(item.creditsCost) ?? 0, data: item.data };
    }),
  };
}

function parseMapResponse(payload: unknown): FirecrawlMapResult {
  const response = requireSuccess(payload, "map");
  return {
    links: records(response.links).flatMap((item) => typeof item.url !== "string" ? [] : [{
      url: item.url,
      title: stringValue(item.title),
      description: stringValue(item.description),
    }]),
  };
}

function retryAfterSeconds(payload: unknown, response: Response): number | undefined {
  const fromBody = isRecord(payload) ? numberValue(payload.retry_after_seconds) : undefined;
  if (fromBody !== undefined) return fromBody;
  const header = Number(response.headers.get("retry-after"));
  return Number.isFinite(header) && header >= 0 ? header : undefined;
}

function sleep(milliseconds: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) return reject(signal.reason);
    const onAbort = () => {
      clearTimeout(timer);
      reject(signal?.reason);
    };
    const timer = setTimeout(() => {
      signal?.removeEventListener("abort", onAbort);
      resolve();
    }, milliseconds);
    signal?.addEventListener("abort", onAbort, { once: true });
  });
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

  async alexandria(call: AlexandriaCall, signal?: AbortSignal): Promise<AlexandriaResponse> {
    // The request id makes a retried execution replay instead of billing twice.
    const headers = { "x-request-id": crypto.randomUUID() };
    return parseAlexandriaResponse(await this.request("scrape", { alexandria: call }, signal, headers));
  }

  async map(options: MapRequest, signal?: AbortSignal): Promise<FirecrawlMapResult> {
    return parseMapResponse(await this.request("map", options, signal));
  }

  private async request(endpoint: string, body: object, signal?: AbortSignal, headers?: Record<string, string>): Promise<unknown> {
    for (let attempt = 0; ; attempt++) {
      signal?.throwIfAborted();
      let response: Response;
      try {
        response = await fetch(`${this.baseUrl}/${endpoint}`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            "Content-Type": "application/json",
            ...headers,
          },
          body: JSON.stringify(body),
          signal,
        });
      } catch (error) {
        if (signal?.aborted || (error instanceof DOMException && error.name === "AbortError")) throw error;
        throw new FirecrawlTransportError();
      }

      if (response.ok) return this.readJson(response, signal);
      const payload = await this.readJson(response, signal);
      const wait = response.status === 429 ? retryAfterSeconds(payload, response) ?? 5 : undefined;
      if (wait !== undefined && attempt < MAX_RATE_LIMIT_RETRIES && wait <= MAX_RATE_LIMIT_WAIT_SECONDS) {
        await sleep(wait * 1000 + 250, signal);
        continue;
      }
      throw new FirecrawlApiError(
        `Firecrawl HTTP ${response.status}: ${isRecord(payload) ? stringValue(payload.error) ?? "request failed" : "request failed"}.`,
        response.status,
        isRecord(payload) ? stringValue(payload.code) : undefined,
      );
    }
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
