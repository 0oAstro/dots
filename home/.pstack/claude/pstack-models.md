# pstack model configuration

Per-role model overrides for pstack skills on Claude Code, loaded through `@~/.claude/pstack-models.md` in CLAUDE.md. Values are Agent tool aliases; `@effort` goes into the Agent tool's `effort` parameter, with subagent_type `pstack:poteto-agent` for code-writing delegates and `general-purpose` otherwise. Evidence and the Pi routes are in ~/.claude/model-routing-policy.md. Delete a line to fall back to the skill default.

feature, refactoring: opus @medium
bug-fix: opus @medium
perf-issue: opus @medium
hillclimb: opus @medium
judgment and prose: opus @high
strongest judgment: fable @xhigh
how explorer: haiku @xhigh
bounded lookups (CLI help, docs, config and quota reads): haiku @xhigh
how explainer: opus @high
why investigators: opus @medium
why synthesizer: opus @high
reflect tooling: opus @medium
reflect judgment, divergent, synthesizer: opus @high
arena runners: opus @medium, opus @low
arena cross-judge pool: opus @medium, opus @low
swarm workers: opus @medium
architect runners: opus @medium
interrogate reviewers: opus @medium, opus @low

default effort: session
session hook: on
