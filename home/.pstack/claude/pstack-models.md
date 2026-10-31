# pstack model configuration

Role overrides for pstack on Claude Code. Pass the alias as the Agent `model` and `@level` as `effort`.

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
session hook: off
