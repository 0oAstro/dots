# pstack model configuration

Per-role model overrides for pstack skills on Claude Code, loaded through `@~/.claude/pstack-models.md` in CLAUDE.md. Values are Agent tool aliases; `@effort` dispatches through the plugin's `pstack:poteto-agent-<effort>` or `pstack:effort-<effort>` agents. Evidence and the Pi routes are in ~/.claude/model-routing-policy.md. Delete a line to fall back to the skill default.

feature, refactoring: opus @medium
bug-fix: opus @medium
perf-issue: opus @medium
hillclimb: opus @medium
judgment and prose: opus @high
strongest judgment: opus @xhigh
how explorer: opus @low
how explainer: opus @high
why investigators: opus @medium
why synthesizer: opus @high
reflect tooling: opus @medium
reflect judgment, divergent, synthesizer: opus @high
arena runners: opus @high, sonnet @xhigh
arena cross-judge pool: opus @high, sonnet @xhigh
swarm workers: opus @medium
architect runners: opus @high, sonnet @xhigh
interrogate reviewers: opus @high, sonnet @xhigh

default effort: session
session hook: off
