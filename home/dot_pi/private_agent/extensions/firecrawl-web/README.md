# Compact Firecrawl web tools

Fulcrum-style Firecrawl integration for Pi. It exposes three focused tools:

- `web_search` — compact Firecrawl v2 web search
- `web_fetch` — cleaned page fetch, with optional focused extraction
- `web_map` — site URL discovery

The extension calls Firecrawl v2 directly. `web_fetch` uses Defuddle with LinkeDOM to clean Firecrawl HTML before returning Markdown.

## Output behavior

- Prefer these native tools for ordinary public-web research. MCP remains useful for unsupported formats, document parsing, and advanced provider controls.
- Search is snippets-only by default. `includeContent: true` requests page Markdown in the same Firecrawl search call and costs extra credits. Content previews preserve Markdown/code formatting; unavailable content is explicitly reported without additional requests.
- Fetch returns the source URL, HTTP status, and cache state/timestamp/age when supplied by Firecrawl. Missing cache information is reported as unknown, not fresh. Known source HTTP errors (400+) fail the tool before focused extraction.
- `maxAge` bounds page cache age in **milliseconds**; `0` requests a fresh fetch. Omit it to retain Firecrawl's default policy. Search accepts it only with `includeContent: true`: it affects scraped pages, not search-index freshness.
- Markdown fetches use lazily loaded Defuddle when HTML is available, falling back to Firecrawl Markdown. `onlyMainContent: false` skips local cleaning. HTML and links are not reprocessed. Screenshot/audio URLs are retained; embedded binary strings are omitted.
- Focused extraction bounds its page input to 120,000 characters. A successful extraction reports if the model did not see the entire source. Fetch without an instruction to retrieve the complete cleaned source instead.

### Long output and continuation

Output is capped by `maxChars` (JavaScript string characters), with additional byte/line safeguards below Pi's tool-output limits. When the selected output is too large, the tool returns a **head preview** and an absolute `fullOutputPath`. Use the existing `read` tool with its line-based `offset` and `limit` to continue, or search the file for a section. No refetch or additional API credits are needed.

The private temporary directory has mode 0700 and its UTF-8 file has mode 0600. Files remain available after the call and across Pi reloads until OS/user temporary-file cleanup; they are not permanent storage and are not automatically removed on tool or session completion. Files contain the complete selected textual output: cleaned page data for ordinary fetch/fallback, or the generated answer for successful focused extraction—not the full source page in that case. Search files contain formatted result previews, not complete scraped pages. No API key, request headers, or embedded binary payloads are written.

Examples:

```js
await tools.web_fetch({ url: "https://docs.python.org/3/library/asyncio-task.html", maxAge: 0 });
await tools.web_search({ query: "Python asyncio TaskGroup", limit: 3, includeContent: true });
```

## Credentials

Set `FIRECRAWL_API_KEY` before starting Pi:

```bash
export FIRECRAWL_API_KEY="fc-..."
```

No config-file, command-resolver, or Keychain credential fallback is supported.

## Focused extraction model

When `web_fetch` receives an `instruction`, it reads the model from `~/.pi/agent/settings.json`:

```json
{
  "firecrawl-web": {
    "fetchModel": "openai-codex/gpt-5.3-codex-spark"
  }
}
```

The value must exactly match a model known to Pi and have working authentication. It defaults to `openai-codex/gpt-5.3-codex-spark` when the setting is absent. `/firecrawl` checks that an API key is configured and shows the selected extraction model; it does not verify network access or model authentication.

## Validation

Run offline regression tests through the installed Pi extension loader (no API/model calls):

```bash
pi --offline -ne -ns -np -nc --no-session -p -e ./tests/run.ts /firecrawl-tests
```

Append `live` to the command prompt (`"/firecrawl-tests live"`) to add bounded real search, long-page fetch, and focused-extraction checks. These spend Firecrawl/model credits.

After updating an installed extension, run `/reload` or start a new Pi session to load the new tool definitions.
