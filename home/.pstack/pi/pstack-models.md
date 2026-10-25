# pstack model configuration

Role overrides for pstack on Pi. Pass the value as the agent `model` and `@level` as `thinking`. Policy: ~/.pi/agent/model-routing-policy.md.

feature, refactoring: azure/gpt-6.1-sol @xhigh
bug-fix: azure/gpt-6.1-sol @xhigh
perf-issue: azure/gpt-6.1-sol @xhigh
hillclimb: azure/gpt-6.1-sol @xhigh
judgment and prose: amazon-bedrock/us.anthropic.claude-opus-5-5 @high
strongest judgment: amazon-bedrock/us.anthropic.claude-fable-5-1 @xhigh
how explorer: amazon-bedrock/us.anthropic.claude-haiku-5-5 @xhigh
how explainer: amazon-bedrock/us.anthropic.claude-opus-5-5 @high
why investigators: amazon-bedrock/us.anthropic.claude-opus-5-5 @medium
why synthesizer: amazon-bedrock/us.anthropic.claude-opus-5-5 @high
reflect tooling: amazon-bedrock/us.anthropic.claude-opus-5-5 @medium
reflect judgment, divergent, synthesizer: amazon-bedrock/us.anthropic.claude-opus-5-5 @high
arena runners: amazon-bedrock/us.anthropic.claude-opus-5-5 @medium, azure/gpt-6.1-sol @xhigh
arena cross-judge pool: amazon-bedrock/us.anthropic.claude-opus-5-5 @medium, azure/gpt-6.1-sol @xhigh
swarm workers: azure/gpt-6.1-sol @xhigh
architect runners: amazon-bedrock/us.anthropic.claude-opus-5-5 @medium
interrogate reviewers: amazon-bedrock/us.anthropic.claude-opus-5-5 @medium, azure/gpt-6.1-sol @xhigh
bounded lookups (CLI help, docs, config and quota reads): azure/deepseek-v4.1-flash @max

default effort: session
session hook: off
pi models: opus=amazon-bedrock/us.anthropic.claude-opus-5-5, fable=amazon-bedrock/us.anthropic.claude-fable-5-1, sonnet=amazon-bedrock/us.anthropic.claude-sonnet-5-5, haiku=amazon-bedrock/us.anthropic.claude-haiku-5-5
