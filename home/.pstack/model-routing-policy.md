# Model routing policy (Claude Code and Pi)

Updated 2026-10-05. Claude is the default. A GPT model takes a role only where it sits on the cost/capability Pareto frontier and no Claude configuration comes close at a comparable cost. Effort is a costed escalation: go one level up after an observed failure, use max only on explicit request, and never use Haiku.

## Routes

| Work | Pi (`bifrost/...`) | Claude Code (Agent aliases) |
| --- | --- | --- |
| Implementation: feature, refactoring, bug-fix, perf-issue, hillclimb, swarm workers | `azure/gpt-6.1-sol @medium` | `opus @medium` |
| Bounded reading: how explorer | `azure/gpt-6.1-sol @medium` | `opus @low` |
| Investigation: why investigators, reflect tooling | `azure/gpt-6.1-sol @medium` | `opus @medium` |
| Judgment and prose: how explainer, why synthesizer, reflect judgment | `anthropic/claude-opus-5-5 @high` | `opus @high` |
| Strongest judgment: hardest ambiguous design, cross-cutting architecture | `anthropic/claude-opus-5-5 @xhigh` | `opus @xhigh` |
| Panels: arena runners, architect runners, interrogate reviewers | Opus `@high`, Sonnet 5.5 `@xhigh`, Sol `@xhigh` | `opus @high`, `sonnet @xhigh` |
| Arena cross-judge pool | Opus `@high`, Sol `@xhigh` | `opus @high`, `sonnet @xhigh` |
| Bounded file or symbol lookup with an exact scope | `azure/gpt-6-luna @xhigh` | direct tools |

The Pi role lines live in `~/.pi/agent/AGENTS.md`. The Claude Code role lines live in `~/.claude/pstack-models.md`, which CLAUDE.md includes. Claude Code's Agent tool can only spawn Claude models.

## Why

- **Claude leads on capability.** Opus 5.5 ranks first on the Epoch Capabilities Index, the AA Intelligence Index, and Epoch's FrontierCode. Sonnet 5.5 max is first on the AA Coding Agent Index.
- **Astra and Fable are dominated.** Opus beats both on every cost-tracked index. For example, Astra high scores 51 at $1.73 and Fable high scores 51 at $3.91, while Opus high scores 54 at $1.82. FrontierSWE is the one exception: Astra max scores 3 points above Opus max at about 10 times the cost. Both models remain available for explicit selection.
- **GPT-6.1 Sol wins on cost below the top.** It owns the frontier up to about 52 on intelligence and about 63 on coding.
  - Sol xhigh matches Sonnet xhigh's coding score (62.9) at 31% of the cost.
  - Sol medium scores 61.4 for $0.70. The cheapest Claude configuration that scores higher is Opus max, at $13.04.
  - So on Pi, Sol takes bulk implementation and bounded reading, and Claude takes everything that needs judgment.
- **Panels mix model families.** Arena, architect, and interrogate depend on reviewers failing in different ways, so the Pi panels keep one Sol seat.
- **Claude Code implementation uses Opus medium, which is inferred.** AA has no coding entry for Opus 5.5 below max. Opus medium scores 51 on intelligence against 47 for Sonnet high, for $0.22 more. On FrontierCode, Opus medium (.546) also beats Sonnet xhigh (.521). Sonnet `@high` (coding 55.0, $1.24) is the measured fallback.

## Evidence

### Epoch Capabilities Index (epoch.ai/benchmarks/eci, data retrieved 2026-10-05)

| Model | ECI | Interval |
| --- | ---: | --- |
| Claude Opus 5.5 | 167.3 | 164.0 to 172.0 |
| GPT-6 Astra | 166.5 | 163.1 to 171.1 |
| Claude Sonnet 5.5 | 165.2 | 161.8 to 169.4 |
| Claude Fable 5.1 | 164.8 | 161.8 to 169.1 |

GPT-6.1 Sol, GPT-6 Sol, and GPT-6 Luna are not scored yet. The four intervals overlap, and ECI has no cost axis.

### Epoch coding benchmarks

- **FrontierCode (Cognition, mean@5, no cost reported):**

  | Model | Score |
  | --- | ---: |
  | Opus 5.5 medium | .546 |
  | Astra max | .533 |
  | Sonnet 5.5 xhigh | .521 |
  | Fable 5.1 medium | .509 |
  | GPT-6.1 Sol medium | .502 |
  | GPT-6 Sol max | .493 |
  | GPT-6 Luna max | .424 |

- **FrontierSWE (proximus harness, max effort):**

  | Model | Score | Cost per task |
  | --- | ---: | ---: |
  | Astra | .655 | $1,030 |
  | Opus 5.5 | .623 | $99 |
  | Sonnet 5.5 | .619 | $110 |
  | Fable 5.1 | .563 | $139 |

### AA Intelligence Index v4.3.2 (score / cost per task)

| Model | low | medium | high | xhigh | max |
| --- | --- | --- | --- | --- | --- |
| Opus 5.5 | 42 / $0.55 | 51 / $1.34 | **54 / $1.82** | **56 / $3.46** | **58 / $5.98** |
| Sonnet 5.5 | 36 / $0.42 | 41 / $0.59 | 47 / $1.12 | 52 / $2.75 | 56 / $7.67 |
| Fable 5.1 | 47 / $2.37 | 49 / $2.98 | 51 / $3.91 | 53 / $5.98 | 53 / $7.63 |
| GPT-6 Astra | 46 / $0.82 | 50 / $1.54 | 51 / $1.73 | 52 / $2.31 | 53 / $3.26 |
| GPT-6.1 Sol | **42 / $0.13** | **48 / $0.21** | **50 / $0.32** | **51 / $0.39** | **52 / $0.72** |
| GPT-6 Luna | **22 / $0.005** | **30 / $0.02** | **33 / $0.03** | **35 / $0.04** | **38 / $0.07** |

Bold marks the all-model Pareto frontier. On the Claude-only frontier, Opus low dominates Sonnet medium, and Opus high dominates Sonnet xhigh.

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
| Sonnet 5.5 high | 55.0 | $1.24 |
| Sonnet 5.5 medium | 45.9 | $0.62 |
| GPT-6 Luna max | 41.1 | $0.18 |

AA reports Opus 5.5 below max only on the Intelligence Index. These are benchmark scores inside each vendor's own harness, not measured success rates in Pi.

The machine-readable AA snapshot is `aa-frontier-2026-09-29.json`. AA's coding-agent entries were unchanged on 2026-10-05.

Sources:
- https://epoch.ai/benchmarks/eci
- https://epoch.ai/data/benchmark_data.zip
- https://artificialanalysis.ai/leaderboards/models
- https://artificialanalysis.ai/agents/coding-agents

## Harness notes

- **Pi:** delegation goes through the pstack extension's `agent` tool. `model` takes a full `provider/id`. A role's `@level` selects the `pstack:poteto-agent-<level>` or `pstack:effort-<level>` subagent type, which sets the child's thinking level.
- **Pi startup effort:** `modelThinkingLevels` in `~/.pi/agent/settings.json` sets it.
- **Pi model cycling:** the order Luna → Sonnet → Sol → Opus → Fable → Astra is a user preference. It is not routing.
- **Claude Code:** `@level` dispatches through the plugin's effort agents. A role without a level keeps the session's effort.
