# pstack model configuration for Codex. One line per role.
# Slugs are confirmed in ~/.codex/bifrost_models.json. Pass effort separately, not as part of the model ID.
# Read ~/.codex/model-routing-policy.md. AA snapshot 2026-09-29 specifically measures GPT-6.1 Sol.
# Coding Agent Index: Sol medium 61.4/$0.70, xhigh 62.9/$1.04; high and max are dominated by medium.
# Luna always uses xhigh (existing user preference) and only handles bounded lookup/tooling.
# GPT-only panels compare efforts and approaches, not independent model families. No max by default.
# budget: per-role (cost/intelligence Pareto; explicit escalation)
feature, refactoring: gpt-6.1-sol (medium)
bug-fix: gpt-6.1-sol (medium)
perf-issue: gpt-6.1-sol (medium)
hillclimb: gpt-6.1-sol (medium)
judgment and prose: gpt-6.1-sol (high)
hardest tasks: gpt-6.1-sol (xhigh)
how explorer: gpt-6-luna (xhigh)
how explainer: gpt-6.1-sol (medium)
why investigators: gpt-6.1-sol (medium)
why synthesizer: gpt-6.1-sol (high)
reflect tooling: gpt-6-luna (xhigh)
reflect judgment, divergent, synthesizer: gpt-6.1-sol (high)
arena runners: gpt-6.1-sol (medium), gpt-6.1-sol (xhigh)
arena cross-judge pool: gpt-6.1-sol (xhigh)
swarm workers: gpt-6.1-sol (medium)
architect runners: gpt-6.1-sol (medium), gpt-6.1-sol (xhigh)
interrogate reviewers: gpt-6.1-sol (medium), gpt-6.1-sol (xhigh)
