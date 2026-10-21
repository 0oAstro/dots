# Model routing policy (Claude Code and Pi)

Updated 2026-10-11. Opus 5.5 is the default session model. A cheaper model takes a role only where it sits on the cost/capability Pareto frontier for that kind of work. Effort is a costed escalation: go one level up after an observed failure, and use max only where a role line names it or on explicit request. Codex is retired. Since 2026-10-11 the Pi role lines centre on the Claude models by user preference: implementation, investigation, architecture, and swarm work run on Opus medium, Fable xhigh takes the strongest-judgment seat, and every panel pairs Opus medium with Sol xhigh. Astra, Kimi K3, and GLM-5.3 Flash hold no role lines and stay in the selector.

## Model chart

The user's cycling order is Kimi K3, DeepSeek V4.1 Flash, GLM-5.3 Flash, Haiku 5.5, GPT-6.1 Sol, Opus 5.5, Fable 5.1, Astra. This order is a preference, not routing. Luna and Sonnet are not in the selector.

## Routes

| Work | Pi (`bifrost/...`) | Claude Code (Agent aliases) |
| --- | --- | --- |
| Implementation: feature, refactoring, bug-fix, perf-issue, hillclimb, swarm workers | `anthropic/claude-opus-5-5 @medium` | `opus @medium` |
| Investigation: why investigators, reflect tooling | `anthropic/claude-opus-5-5 @medium` | `opus @medium` |
| Bounded reading: how explorer, bounded lookups (CLI help, docs, config and quota reads) | `anthropic/claude-haiku-5-5 @xhigh` | `haiku @xhigh` |
| Judgment and prose: how explainer, why synthesizer, reflect judgment | `anthropic/claude-opus-5-5 @high` | `opus @high` |
| Strongest judgment: hardest ambiguous design, cross-cutting architecture | `anthropic/claude-fable-5-1 @xhigh` | `fable @xhigh` |
| Architect runners | `anthropic/claude-opus-5-5 @medium` | `opus @medium` |
| Arena runners, interrogate reviewers, arena cross-judge pool | Opus `@medium`, Sol `@xhigh` | `opus @medium`, `opus @low` (Opus low takes the Sol seat) |

The Pi role lines live in `~/.pi/agent/AGENTS.md`. The Claude Code role lines live in `~/.claude/pstack-models.md`, which CLAUDE.md includes. Claude Code's Agent tool can only spawn Claude models.

## Why

- **Opus leads on capability.** Opus 5.5 is first on the AA Intelligence Index at every effort from high up, first on the Epoch Capabilities Index, and first on Epoch's FrontierCode.
- **GPT-6.1 Sol owns the middle of the frontier but gives up its role lines by user preference (2026-10-11).** Sol medium scores 48 for $0.21 and Sol xhigh 51 for $0.39. The cheapest Claude configuration that matches Sol xhigh is Opus medium at $1.34, more than three times the cost. On AA's Coding Agent Index, Sol medium (61.4, $0.70) and Sol xhigh (62.9, $1.04) beat every Claude configuration below Opus max ($13.04). The user still routes implementation and investigation to Opus medium to keep pstack work on the Claude models. Sol stays in the selector.
- **Haiku 5.5 replaces Luna at the bottom.** Haiku xhigh scores 41 for $0.12, against 38 for $0.07 from Luna max. Haiku is also the fastest model on the chart (about 190 to 240 tokens per second), which suits bounded reading. Luna is no longer routed or listed.
- **Fable and Astra are dominated on the frontier but routed by user preference (2026-10-11).** Opus high (54, $1.82) beats Fable high (51, $3.91) and Astra high (51, $1.73) for about the same cost or less. The user accepts this big-model smell for the strongest-judgment seat, which Fable xhigh now holds. Astra holds no role line. Both stay in the selector. Fable's Pi thinking map exposes only xhigh and max, so the Fable seat runs xhigh.
- **GLM-5.3 Flash replaces GLM-5.3.** Flash scores 42 for $0.25 against 45 for $2.01 from GLM-5.3 max: three points less for an eighth of the cost. It sits just off the frontier (Sol low scores 42 for $0.13), Panels now pair Opus medium with Sol xhigh, so Flash holds no role line and stays in the selector at session level max (2026-10-11).
- **Kimi K3 is off the frontier and now selector-only (2026-10-11).** Kimi K3 max scores 44 for $2.00, below Sol medium at a tenth of the price. Sol xhigh takes its interrogate seat. Session level is max.
- **Sonnet is dropped.** Opus low (42, $0.55) beats Sonnet medium (41, $0.48) at about the same cost, and Opus high beats Sonnet xhigh. The alias stays mapped for skills that name it.
- **Claude Code panels vary effort, not family.** The Agent tool cannot spawn non-Claude models, so Opus low takes the Sol seat in Claude Code panels (user choice, 2026-10-14). Opus low (42, $0.55) matches Sol low on the AA index. Claude Code panels record the reduced diversity.

## Evidence

### AA Intelligence Index (score / cost per task, retrieved 2026-10-11)

| Model | low | medium | high | xhigh | max |
| --- | --- | --- | --- | --- | --- |
| Opus 5.5 | 42 / $0.55 | 51 / $1.34 | **54 / $1.82** | **56 / $3.46** | **58 / $5.98** |
| Sonnet 5.5 | 36 / $0.35 | 41 / $0.48 | 47 / $0.88 | 52 / $2.01 | 56 / $5.46 |
| Haiku 5.5 | **29 / $0.02** | **34 / $0.05** | **38 / $0.08** | **41 / $0.12** | 43 / $0.21 |
| Fable 5.1 | 47 / $2.37 | 49 / $2.98 | 51 / $3.91 | 53 / $5.98 | 53 / $7.63 |
| GPT-6 Astra | 46 / $0.82 | 50 / $1.54 | 51 / $1.73 | 52 / $2.31 | 53 / $3.26 |
| GPT-6.1 Sol | **42 / $0.13** | **48 / $0.21** | **50 / $0.32** | **51 / $0.39** | **52 / $0.72** |
| GLM-5.3 (removed) | 34 / $0.85 | | | | 45 / $2.01 |
| GLM-5.3 Flash | | | | | 42 / $0.25 |
| Kimi K3 | 30 / $1.15 | | | | 44 / $2.00 |

Bold marks the frontier among the routed models. GPT-6 Luna (38 / $0.07 at max) is dropped by user preference. Blank cells are not published.

### AA Coding Agent Index v1.5 (harness included: Claude Code for Claude, Codex for GPT)

| Configuration | Score | Cost per task |
| --- | ---: | ---: |
| Sonnet 5.5 max | 68.4 | $14.19 |
| Opus 5.5 max | 66.0 | $13.04 |
| Sol xhigh | 62.9 | $1.04 |
| Sonnet 5.5 xhigh | 62.9 | $3.33 |
| Fable 5.1 max | 62.2 | $12.39 |
| Astra max | 61.6 | $7.47 |
| Sol medium | 61.4 | $0.70 |
| Sol low | 57.2 | $0.50 |

These numbers were retrieved 2026-09-29. On 2026-10-11 the AA page listed its scores as "Not publicly available", so they could not be refreshed. Haiku, Kimi, and GLM have no entry.

### Epoch

- **Capabilities Index (2026-10-05):** Opus 5.5 167.3, Astra 166.5, Sonnet 5.5 165.2, Fable 5.1 164.8. The intervals overlap.
- **FrontierCode (mean@5):** Opus medium .546, Astra max .533, Sonnet xhigh .521, Fable medium .509, Sol medium .502.

### Pi codemode check (2026-10-11, this host)

A three-task fixture (count and cross-reference files, fix a failing test, rename a symbol across files), with two runs per model and codemode `only`. Every model passed 6 of 6, with no failed scripts: Kimi K3 (Azure), GLM-5.3, GLM-5.3 Flash, Haiku 5.5, Sol, Opus 5.5, Fable 5.1, Astra, Sonnet 5.5. This is a smoke test of tool use, not a capability ranking.

Sources:
- https://artificialanalysis.ai/leaderboards/models
- https://artificialanalysis.ai/agents/coding-agents
- https://epoch.ai/benchmarks/eci

## Harness notes

- **Pi:** delegation goes through the pstack extension's `agent` tool. `model` takes a full `provider/id`. A role's `@level` selects the `pstack:poteto-agent-<level>` or `pstack:effort-<level>` subagent type, which sets the child's thinking level.
- **Pi thinking maps:** GLM-5.3 Flash is thinking-only and accepts `low` through `high` and `max`. Kimi K3 also accepts `low` through `high` and `max`. Fable 5.1 exposes only `xhigh` and `max`.
- **Pi startup effort:** `modelThinkingLevels` in `~/.pi/agent/settings.json` sets it.
- **Azure Fireworks quota:** the GlobalStandard Fireworks quota in southindia is 2000K TPM. `fw-glm-5.3-flash` takes 1000K. Kimi K3 now uses the existing AWS US profile, `bedrock/moonshotai.kimi-k3`, through Bifrost.
- **Current backends:** DeepSeek V4.1 Flash uses Azure, `azure/deepseek-v4.1-flash`, through Bifrost. Its session level is max.
