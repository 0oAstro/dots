# pstack model configuration

Per-role model overrides for pstack skills on Pi. The pstack Pi extension adds this sheet to every session's system prompt, child agents included. Pass a role's value as the `agent` tool's `model` and its `@<level>` as `effort`. Use subagent_type `pstack:poteto-agent` for code-writing delegates and `general-purpose` otherwise. Evidence: ~/.pi/agent/model-routing-policy.md.

feature, refactoring: bifrost/azure/gpt-6.1-sol @xhigh
bug-fix: bifrost/azure/gpt-6.1-sol @xhigh
perf-issue: bifrost/azure/gpt-6.1-sol @xhigh
hillclimb: bifrost/azure/gpt-6.1-sol @xhigh
judgment and prose: bifrost/anthropic/claude-opus-5-5 @high
strongest judgment: bifrost/anthropic/claude-fable-5-1 @xhigh
how explorer: bifrost/anthropic/claude-haiku-5-5 @xhigh
how explainer: bifrost/anthropic/claude-opus-5-5 @high
why investigators: bifrost/anthropic/claude-opus-5-5 @medium
why synthesizer: bifrost/anthropic/claude-opus-5-5 @high
reflect tooling: bifrost/anthropic/claude-opus-5-5 @medium
reflect judgment, divergent, synthesizer: bifrost/anthropic/claude-opus-5-5 @high
arena runners: bifrost/anthropic/claude-opus-5-5 @medium, bifrost/azure/gpt-6.1-sol @xhigh
arena cross-judge pool: bifrost/anthropic/claude-opus-5-5 @medium, bifrost/azure/gpt-6.1-sol @xhigh
swarm workers: bifrost/azure/gpt-6.1-sol @xhigh
architect runners: bifrost/anthropic/claude-opus-5-5 @medium
interrogate reviewers: bifrost/anthropic/claude-opus-5-5 @medium, bifrost/azure/gpt-6.1-sol @xhigh
bounded lookups (CLI help, docs, config and quota reads): bifrost/azure/deepseek-v4.1-flash @max

default effort: session
session hook: off
pi models: opus=bifrost/anthropic/claude-opus-5-5, fable=bifrost/anthropic/claude-fable-5-1, sonnet=bifrost/anthropic/claude-sonnet-5-5, haiku=bifrost/anthropic/claude-haiku-5-5
