# Deferred delegation tools

The historical package path is retained so existing Pi settings continue to load it.
It loads the installed pi-subagents package and suppresses its redundant
`subagents_enable` loader, as before. The large `subagent` and `bg_wait` tools are
now registered with native Pi `deferred` exposure. Use built-in `tool_search` to
load them for direct calls; they also remain callable from codemode scripts.
Their full parameters, handlers, renderers and safety guidance are unchanged.
Supervisor controls remain directly available. Registration is intercepted before
activation, so new sessions do not first load and then remove their declarations.
There is no per-turn tool unloading or active-tool reset; Pi owns resumed/forked
selection state.

## Configuration

- `~/.pi/agent/settings.json`: `defaultTools` includes `+codemode`, `+tool_search`;
  it no longer forces `+subagent`.
- `~/.pi/agent/models.json`: Bifrost Azure Luna, Sol and Astra declare both
  `supportsToolSearch` and `supportsMidConvoSystemMessages`. The latter is needed
  for Pi to preserve transcript-anchored additions rather than collapsing them.
- Executor MCP stays `codemode-deferred`: its schemas stay out of initial context,
  and either codemode discovery or tool_search can reach them.

Keep frequent read/bash/edit/write, web, process, todo and user-question tools eager.
Codemode remains in its normal mode for batching and result filtering. Do not
switch everything to deferred or codemode-only without separate evidence.

Tool discovery does not authorize delegation. Direct execution remains the
default; only operator-requested or instruction-authorized child work is permitted.
Load `subagent` before managing runs, then use `action: list, capabilities: true`
for capability discovery. No child agents were launched during validation.

## Verification and rollback

Validated through actual Pi 0.99.1 requests to Bifrost v2.2.4. Loaded tools appeared
in `tool_search_output` input items with `defer_loading: true`, leaving the initial
tool declarations unchanged. The full-config Sol test loaded `subagent` and read
its capability list. Its continuations reported cached input tokens; this is not
a comparative latency/cost benchmark.

Reload Pi or start a fresh session to apply. Existing resumed transcripts that
already contain tool removals/redefinitions can still trigger Pi's safe full-list
fallback, so a fresh session gives the clearest prompt-prefix benefit.

To restore eager delegation, add `+subagent` to `defaultTools` and register tools
unchanged in index.ts (`if (tool.name !== "subagents_enable") target.registerTool(tool)`).
To disable built-in search as before, replace `+tool_search` with `-tool_search`.
The validated model compatibility settings can remain; without dynamic additions
they do not change tool selection.
