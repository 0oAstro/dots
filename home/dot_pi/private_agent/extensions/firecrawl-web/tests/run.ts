import assert from "node:assert/strict";
import { readFile, rm, stat } from "node:fs/promises";
import { dirname } from "node:path";
import type { ExtensionAPI, ToolDefinition } from "@earendil-works/pi-coding-agent";
import firecrawlWeb, { boundedOutput, presentScrape } from "../index.js";
import { FirecrawlApiError, FirecrawlClient } from "../client.js";
import { cleanFirecrawlHtml, extractFirecrawlContent } from "../content.js";

// Run through Pi's extension loader: it supplies the host packages and schemas.
export default function tests(pi: ExtensionAPI) {
  pi.registerCommand("firecrawl-tests", {
    description: "Run offline Firecrawl regression tests; 'live' adds bounded API checks",
    handler: async (args, ctx) => {
      const tools = new Map<string, ToolDefinition>();
      firecrawlWeb({
        registerTool: (tool: ToolDefinition) => tools.set(tool.name, tool),
        registerCommand: () => {},
      } as unknown as ExtensionAPI);
      const originalFetch = globalThis.fetch;
      const originalKey = process.env.FIRECRAWL_API_KEY;
      const temporaryDirectories = new Set<string>();
      let passed = 0;
      let failed = 0;
      let requests: { url: string; body: any }[] = [];
      const check = async (name: string, test: () => unknown) => {
        try { await test(); passed++; console.log(`PASS ${name}`); }
        catch (error) { failed++; console.error(`FAIL ${name}:`, error); }
      };
      const mock = (payload: unknown, status = 200) => {
        requests = [];
        globalThis.fetch = async (url, init) => {
          requests.push({ url: String(url), body: JSON.parse(String(init?.body)) });
          return new Response(JSON.stringify(payload), { status, headers: { "Content-Type": "application/json" } });
        };
      };
      const execute = async (name: string, params: any, signal?: AbortSignal, context: any = { modelRegistry: { find: () => undefined } }) => {
        const result = await tools.get(name)!.execute("test-call", params, signal, undefined, context);
        const path = (result.details as any)?.fullOutputPath;
        if (path) temporaryDirectories.add(dirname(path));
        return result;
      };
      const text = (result: any): string => result.content.map((item: any) => item.text ?? "").join("\n");
      const page = "# Exact documentation\n\n```js\nconst keep = 'this code';\n```\n\n| A | B |\n|---|---|\n| 1 | 2 |";
      const search = { success: true, data: { web: [{ url: "https://nodejs.org/api/test.html", title: "Test runner", description: "Mock timers documentation", markdown: page }] } };
      process.env.FIRECRAWL_API_KEY = "test-key-not-real";
      try {
        await check("native tool set remains search, fetch, map", () => {
          assert.deepEqual([...tools.keys()], ["web_search", "web_fetch", "web_map"]);
          assert.match(tools.get("web_search")!.promptGuidelines!.join(" "), /Prefer native/);
          for (const name of ["web_search", "web_fetch"]) {
            assert.equal((tools.get(name)!.parameters as any).properties.maxAge.minimum, 0);
          }
        });
        await check("default search remains compact and does not scrape", async () => {
          mock(search);
          const result = await execute("web_search", { query: "nodejs mock timers" });
          assert.equal(requests[0].body.limit, 5);
          assert.deepEqual(requests[0].body.sources, ["web"]);
          assert.equal(requests[0].body.scrapeOptions, undefined);
          assert.doesNotMatch(text(result), /Content:/);
          assert.equal((result.details as any).fullOutputPath, undefined);
        });
        await check("includeContent requests Markdown once and preserves code", async () => {
          mock(search);
          const result = await execute("web_search", { query: "test", includeContent: true, maxAge: 0 });
          assert.deepEqual(requests[0].body.scrapeOptions, { formats: ["markdown"], onlyMainContent: true, maxAge: 0 });
          assert.equal(requests.length, 1);
          assert.match(text(result), /Content:\n# Exact documentation/);
          assert.match(text(result), /```js\nconst keep/);
          assert.equal((result.details as any).results[0].markdown, undefined);
        });
        await check("missing search content is explicit, with no retry scrape", async () => {
          mock({ success: true, data: { web: [{ url: "https://example.com", title: "Page" }] } });
          const result = await execute("web_search", { query: "test", includeContent: true });
          assert.match(text(result), /Page content unavailable/);
          assert.equal(requests.length, 1);
        });
        await check("domain and recency options still reach Firecrawl", async () => {
          mock(search);
          await execute("web_search", { query: " test ", includeDomains: ["nodejs.org"], recency: "week", includeContent: true, maxAge: 60000 });
          assert.deepEqual(requests[0].body.includeDomains, ["nodejs.org"]);
          assert.equal(requests[0].body.tbs, "qdr:w");
          assert.equal(requests[0].body.query, "test");
          assert.equal(requests[0].body.scrapeOptions.maxAge, 60000);
        });
        await check("invalid search combinations fail before networking", async () => {
          mock(search);
          for (const params of [{ query: " " }, { query: "test", maxAge: 0 }, { query: "test", includeDomains: ["a.com"], excludeDomains: ["b.com"] }]) {
            await assert.rejects(execute("web_search", params));
          }
          assert.equal(requests.length, 0);
        });
        await check("search warnings remain visible", async () => {
          mock({ success: true, warning: "Partial result", warnings: ["Partial result", "Limited"], data: { web: [] } });
          assert.match(text(await execute("web_search", { query: "test" })), /Warning: Partial result; Limited/);
        });
        await check("fetch freshness omitted, zero and positive values survive", async () => {
          for (const maxAge of [undefined, 0, 60000]) {
            mock({ success: true, data: { markdown: page, metadata: { statusCode: 200 } } });
            const result = await execute("web_fetch", { url: "https://example.com", maxAge });
            assert.equal(requests[0].body.maxAge, maxAge);
            assert.deepEqual(requests[0].body.formats, ["markdown", "html"]);
            assert.match(text(result), /HTTP: 200; cache=unknown/);
            assert.match(text(result), /const keep/);
          }
        });
        await check("fetch shows only allowlisted cache metadata and warnings", async () => {
          mock({ success: true, warning: "Top warning", data: { warning: "Page warning", markdown: page, metadata: { statusCode: 200, cacheState: "hit", cachedAt: "2026-01-01T00:00:00Z", arbitrary: "DO_NOT_PRINT" } } });
          const result = await execute("web_fetch", { url: "https://example.com" });
          assert.match(text(result), /cache=hit; cachedAt=2026-01-01T00:00:00Z; age=\d+s/);
          assert.match(text(result), /Top warning; Page warning/);
          assert.doesNotMatch(text(result), /DO_NOT_PRINT/);
        });
        await check("absent and fresh cache metadata are not confused", async () => {
          for (const metadata of [{}, { statusCode: 200, cacheState: "miss" }]) {
            mock({ success: true, data: { markdown: page, metadata } });
            const result = text(await execute("web_fetch", { url: "https://example.com" }));
            assert.match(result, metadata.statusCode ? /HTTP: 200; cache=miss/ : /HTTP: unknown; cache=unknown/);
            assert.doesNotMatch(result, /cachedAt=|age=/);
          }
        });
        await check("target HTTP failures are not successful fetches", async () => {
          for (const statusCode of [403, 404, 500]) {
            mock({ success: true, data: { markdown: "Access denied", metadata: { statusCode } } });
            await assert.rejects(execute("web_fetch", { url: "https://example.com", instruction: "Summarize" }), new RegExp(`HTTP ${statusCode}`));
          }
        });
        await check("onlyMainContent=false preserves original Markdown", async () => {
          mock({ success: true, data: { markdown: page, html: "<article>Wrong replacement</article>", metadata: {} } });
          const result = await execute("web_fetch", { url: "https://example.com", onlyMainContent: false });
          assert.match(text(result), /const keep/);
          assert.equal((result.details as any).cleaner, "firecrawl");
        });
        await check("focused fallback shares metadata and requests cleaning HTML", async () => {
          mock({ success: true, data: { markdown: page, metadata: { statusCode: 200, cacheState: "hit" } } });
          const result = await execute("web_fetch", { url: "https://example.com", instruction: "Find code", formats: ["links"] });
          assert.deepEqual(requests[0].body.formats, ["links", "markdown", "html"]);
          assert.match(text(result), /HTTP: 200; cache=hit/);
          assert.match(text(result), /Focused extraction unavailable/);
          assert.match(text(result), /const keep/);
          assert.equal((result.details as any).focused, false);
        });
        await check("blank instruction and HTML-only calls do not add Markdown", async () => {
          mock({ success: true, data: { html: "<article>Keep exact HTML</article>", metadata: {} } });
          const result = await execute("web_fetch", { url: "https://example.com", instruction: " ", formats: ["html"] });
          assert.deepEqual(requests[0].body.formats, ["html"]);
          assert.match(text(result), /<article>Keep exact HTML<\/article>/);
        });
        await check("screenshot URLs and branding survive presentation", async () => {
          mock({ success: true, data: { screenshot: "https://cdn.example.com/image.png", branding: { colors: { primary: "#123456" } }, metadata: {} } });
          const result = await execute("web_fetch", { url: "https://example.com", formats: ["screenshot", "branding"] });
          assert.match(text(result), /https:\/\/cdn.example.com\/image.png/);
          assert.match(text(result), /#123456/);
        });
        await check("raw binary payload stays out of text", async () => {
          mock({ success: true, data: { screenshot: "data:image/png;base64,SECRET_BINARY", metadata: {} } });
          const result = await execute("web_fetch", { url: "https://example.com", formats: ["screenshot"] });
          assert.match(text(result), /binary payload omitted/);
          assert.doesNotMatch(text(result), /SECRET_BINARY/);
        });
        await check("missing requested content is explicit", async () => {
          mock({ success: true, data: { metadata: {} } });
          assert.match(text(await execute("web_fetch", { url: "https://example.com" })), /No content returned/);
        });
        await check("complete long page is recoverable, private and stable", async () => {
          const markdown = "FIRST\n" + "line\n".repeat(500) + "MIDDLE\n" + "line\n".repeat(500) + "LAST";
          mock({ success: true, data: { markdown, metadata: {} } });
          const result = await execute("web_fetch", { url: "https://example.com", maxChars: 1000 });
          const path = (result.details as any).fullOutputPath;
          assert.ok(text(result).length <= 1000);
          assert.match(text(result), /Output truncated/);
          assert.match(text(result), /Use read with offset\/limit/);
          assert.ok(text(result).includes(path));
          assert.doesNotMatch(text(result), /MIDDLE|LAST/);
          assert.equal(await readFile(path, "utf8"), "URL: https://example.com\nHTTP: unknown; cache=unknown\n\n" + markdown);
          assert.equal((await stat(path)).mode & 0o777, 0o600);
          assert.equal((await stat(dirname(path))).mode & 0o777, 0o700);
          const second = await execute("web_fetch", { url: "https://example.com", maxChars: 1000 });
          assert.notEqual((second.details as any).fullOutputPath, path);
        });
        await check("lists do not discard item 101 before saving", async () => {
          const links = Array.from({ length: 150 }, (_, i) => `https://example.com/${i + 1}`);
          mock({ success: true, data: { links, metadata: {} } });
          const result = await execute("web_fetch", { url: "https://example.com", formats: ["links"], maxChars: 1000 });
          const full = await readFile((result.details as any).fullOutputPath, "utf8");
          assert.match(full, /https:\/\/example.com\/101\n/);
          assert.ok(full.endsWith(links[149]));
        });
        await check("search and map truncation also have complete files", async () => {
          for (const name of ["web_search", "web_map"]) {
            const items = Array.from({ length: 20 }, (_, i) => ({ url: `https://example.com/${i}`, title: "Long title ".repeat(20), description: "words ".repeat(100) }));
            mock(name === "web_search" ? { success: true, data: { web: items } } : { success: true, links: items });
            const result = await execute(name, { query: "test", url: "https://example.com", maxChars: 1000 });
            assert.ok(text(result).length <= 1000);
            assert.match(await readFile((result.details as any).fullOutputPath, "utf8"), /https:\/\/example.com\/19/);
          }
        });
        await check("Unicode byte limits and excessive lines preserve the notice", async () => {
          for (const markdown of ["漢".repeat(18000), "line\n".repeat(2000), "x".repeat(50000)]) {
            mock({ success: true, data: { markdown, metadata: {} } });
            const result = await execute("web_fetch", { url: "https://example.com", maxChars: 40000 });
            assert.ok(Buffer.byteLength(text(result)) < 50000);
            assert.ok(text(result).split("\n").length < 2000);
            assert.ok(text(result).length <= 40000);
            assert.match(text(result), /Full output:/);
            assert.ok((await readFile((result.details as any).fullOutputPath, "utf8")).endsWith(markdown.trim()));
          }
        });
        await check("exact character boundary does not allocate a temp file", async () => {
          const header = "URL: https://example.com\nHTTP: unknown; cache=unknown\n\n";
          mock({ success: true, data: { markdown: "x".repeat(1000 - header.length), metadata: {} } });
          const result = await execute("web_fetch", { url: "https://example.com", maxChars: 1000 });
          assert.equal(text(result).length, 1000);
          assert.equal((result.details as any).fullOutputPath, undefined);
        });
        await check("pre-aborted requests never reach Firecrawl", async () => {
          mock(search);
          await assert.rejects(execute("web_search", { query: "test" }, AbortSignal.abort(new Error("user cancelled"))), /user cancelled/);
          assert.equal(requests.length, 0);
        });
        await check("cancellation during JSON reading remains cancellation", async () => {
          const controller = new AbortController();
          globalThis.fetch = async () => ({ ok: true, status: 200, json: async () => { controller.abort(new Error("body cancelled")); throw controller.signal.reason; } }) as Response;
          await assert.rejects(execute("web_search", { query: "test" }, controller.signal), /body cancelled/);
        });
        await check("cancellation during pending model resolution rejects instead of fallback", async () => {
          const controller = new AbortController();
          let resolveAuth!: (value: any) => void;
          const auth = new Promise((resolve) => { resolveAuth = resolve; });
          const result = extractFirecrawlContent({
            registry: { find: () => ({ input: ["text"] }), getApiKeyAndHeaders: () => auth } as any,
            model: "test/model", url: "https://example.com", markdown: page,
            instruction: "Find code", maxOutput: 1000, signal: controller.signal,
          });
          const rejection = assert.rejects(result, /cancelled during resolution/);
          controller.abort(new Error("cancelled during resolution"));
          resolveAuth({ ok: false });
          await rejection;
        });
        await check("long successful focused output keeps source-limitation warning before preview", async () => {
          const body = presentScrape({ metadata: { statusCode: 200 } }, "https://example.com", ["markdown"], {
            extracted: { text: "ANSWER".repeat(400), inputTruncated: true, model: "test/model", usage: {} as any },
          });
          const result = await boundedOutput(body, 1000);
          temporaryDirectories.add(dirname(result.fullOutputPath!));
          assert.ok(result.text.length <= 1000);
          assert.match(result.text, /model did not see the entire page/);
          assert.ok(result.text.includes(result.fullOutputPath!));
          assert.equal(await readFile(result.fullOutputPath!, "utf8"), body);
        });
        await check("long focused fallback keeps unavailable notice before preview", async () => {
          mock({ success: true, data: { markdown: "line\n".repeat(1000), metadata: {} } });
          const result = await execute("web_fetch", { url: "https://example.com", instruction: "Find code", maxChars: 1000 });
          assert.match(text(result), /Focused extraction unavailable/);
          assert.ok(text(result).includes((result.details as any).fullOutputPath));
        });
        await check("cancellation during asynchronous output publication never returns a path", async () => {
          const controller = new AbortController();
          const pending = boundedOutput("x".repeat(100000), 1000, controller.signal);
          const rejection = assert.rejects(pending, /cancelled during publication/);
          controller.abort(new Error("cancelled during publication"));
          await rejection;
        });
        await check("API errors retain numeric HTTP status", async () => {
          mock({ error: "Quota" }, 429);
          await assert.rejects(new FirecrawlClient("test").search({ query: "test", sources: ["web"] }), (error: unknown) => error instanceof FirecrawlApiError && error.status === 429);
          globalThis.fetch = async () => new Response("Bad Gateway", { status: 502 });
          await assert.rejects(execute("web_search", { query: "test" }), /non-JSON response \(HTTP 502\)/);
        });
        await check("Defuddle cleaning retains documentation code and tables", async () => {
          const html = `<html><head><title>Docs</title></head><body><nav>Unrelated navigation</nav><article><h1>Exact documentation</h1><p>${"Useful documentation for the function and its arguments. ".repeat(30)}</p><pre><code class="language-js">const keep = 'this code';</code></pre><table><tr><th>A</th><th>B</th></tr><tr><td>1</td><td>2</td></tr></table></article></body></html>`;
          const cleaned = await cleanFirecrawlHtml(html, "https://example.com");
          assert.ok(cleaned);
          assert.match(cleaned, /const keep/);
          assert.match(cleaned, /\|.*1.*\|.*2.*\|/);
        });
        await check("collapsed errors show their actual error text", () => {
          const result = { content: [{ type: "text", text: "Page fetch failed (HTTP 403)" }] };
          const theme = { fg: (_color: string, value: string) => value, bold: (value: string) => value };
          for (const name of ["web_search", "web_fetch", "web_map"]) {
            const component = tools.get(name)!.renderResult!(result as any, { expanded: false, isPartial: false }, theme as any, { isError: true } as any);
            assert.match(component.render(200).join("\n"), /HTTP 403/);
          }
        });
        await check("search deduplication preserves case-sensitive paths", async () => {
          mock({ success: true, data: { web: [{ url: "https://example.com/A", title: "Upper" }, { url: "https://example.com/a", title: "Lower" }] } });
          const result = await execute("web_search", { query: "test" });
          assert.match(text(result), /Upper/);
          assert.match(text(result), /Lower/);
        });
        await check("expanded renderers show returned text", async () => {
          mock(search);
          const result = await execute("web_search", { query: "test" });
          const theme = { fg: (_color: string, value: string) => value, bold: (value: string) => value };
          const component = tools.get("web_search")!.renderResult!(result, { expanded: true, isPartial: false }, theme as any, {} as any);
          assert.match(component.render(200).join("\n"), /URL: https:\/\/nodejs.org/);
        });
      } finally {
        globalThis.fetch = originalFetch;
        if (originalKey === undefined) delete process.env.FIRECRAWL_API_KEY;
        else process.env.FIRECRAWL_API_KEY = originalKey;
      }
      if (args.trim() === "live" && !failed) {
        await check("LIVE includeContent returns page Markdown", async () => {
          const result = await execute("web_search", { query: "Python asyncio TaskGroup", includeDomains: ["docs.python.org"], limit: 1, includeContent: true });
          assert.match(text(result), /Content:/);
          console.log(text(result).slice(0, 1800));
        });
        await check("LIVE long fetch keeps metadata and recoverable complete source", async () => {
          const result = await execute("web_fetch", { url: "https://docs.python.org/3/library/asyncio-task.html", maxChars: 1000 });
          assert.match(text(result), /HTTP: 200; cache=/);
          assert.ok((await readFile((result.details as any).fullOutputPath, "utf8")).length > 40000);
          console.log(text(result));
        });
        await check("LIVE focused output retains its source envelope", async () => {
          const result = await execute("web_fetch", { url: "https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/429", instruction: "Return the HTTP status code and the retry guidance header NAME, not value.", maxAge: 0, maxChars: 2000 }, undefined, ctx);
          assert.match(text(result), /HTTP: 200; cache=/);
          assert.match(text(result), /Retry-After/);
          assert.equal((result.details as any).focused, true);
          console.log(text(result));
        });
      }
      for (const directory of temporaryDirectories) await rm(directory, { recursive: true, force: true });
      console.log(`\nFirecrawl: ${passed} passed, ${failed} failed.`);
      if (failed) process.exitCode = 1;
    },
  });
}
