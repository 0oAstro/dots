# Pi Herdr activity reporting

User-owned replacement for the installed Herdr Pi v9 reporter. The managed file at `~/.pi/agent/extensions/herdr-agent-state.ts` is left unchanged and excluded through `settings.json`; this package is loaded through `local/pi-herdr-state`. Keeping the replacement separate prevents `herdr integration install pi` from overwriting it.

## Behavior

- Freshly opened, resumed, or reloaded idle sessions report `unknown` until this reporter observes main-agent or background work. Herdr 0.9.1 displays `unknown` as neutral idle; unlike `idle`, it does not project an unseen session as **done**. Session identity and lifecycle authority remain intact. Empty status snapshots, stray completion events, and startup questions do not count as work.
- Report `working` while the main agent is active **or** background subagent/workflow work remains. Report `idle` only after observed work settles and all background work finishes; normal completion badges still work. Reset observed-work tracking at session shutdown.
- Honor pi-subagents' counted `herdr:busy` signal and track async runs by ID through its current `subagent:async-started` and `subagent:async-complete` events. Concurrent completion, failure, and stop cannot idle the pane until the last run finishes.
- Restore already-running/queued work through the public, read-only `subagents:rpc:v1:request` status API at session startup and `subagents:rpc:v1:ready`. Use the versioned async snapshot's `state` field, not internal job fields. Ignore replies overtaken by lifecycle changes; expire unanswered requests after two seconds.
- Use only the installed pi-subagents public event and RPC contracts; do not poll private registries or run artifacts.
- Preserve blocked-state priority, native root-session identity, report sequencing, bounded socket attempts, and latest-state queueing from Herdr v9.
- Activate only in root TUI sessions; remain inert outside Herdr and in RPC/JSON/print children. Dispose listeners and outstanding activity requests at session shutdown.

## Activation

New Pi windows load the fix automatically. In existing windows, run `/reload` **after active subagents finish**. pi-subagents aborts active workflow controllers during `session_shutdown`, which reload invokes. A Herdr restart or config reload is not needed. Editing this package does not hot-patch extensions already loaded in running Pi windows.

## Tests

```sh
cd ~/.pi/agent/local/pi-herdr-state
npm test
```

The 25 deterministic tests exercise the replacement source using a fake socket, event bus, and clock. They cover fresh-session neutral reporting, idle startup/reload/resume/new, first-turn completion, startup blocking, work under a blocker, completion reset across sessions, parent-idle/background-busy, counted busy signals, concurrent completion/failure/stop, duplicate lifecycle events, startup restoration without an initial completion report, load order, stale RPC replies, missing providers, blocked priority, headless children, and cleanup. Integration cases import the actual installed pi-subagents Herdr bridge and public snapshot builder so obsolete event names or snapshot fields cannot silently pass against a fabricated manager API.

The TypeScript source also imports successfully through the installed `jiti` loader. The existing settings still load this package and exclude the managed original; no settings change is required.

## Rollback

Remove `local/pi-herdr-state` from `packages` and `-extensions/herdr-agent-state.ts` from `extensions` in `~/.pi/agent/settings.json`, then reload Pi after running agents finish. A pre-change snapshot is in `~/.agents/herdr-subagent-backup-2026-09-29/`; use it for reference rather than overwriting unrelated later settings changes.
