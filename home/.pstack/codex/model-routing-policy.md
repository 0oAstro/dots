# Model and reasoning policy

Updated 2026-09-29 using Artificial Analysis Intelligence Index v4.3.2 and Coding Agent Index v1.5. Optimize cost per successful task, not token price or brand reputation.

## Routing

| Work | Model | Effort |
| --- | --- | --- |
| Main Pi session, ordinary coding, refactoring, tests, open-ended investigation | bifrost/azure/gpt-6.1-sol | medium |
| Bounded file/symbol lookup or structured extraction with an exact scope | bifrost/azure/gpt-6-luna | xhigh |
| Budget-sensitive non-coding reasoning | bifrost/azure/gpt-6.1-sol | high |
| Difficult bounded refactoring or implementation | bifrost/azure/gpt-6.1-sol | xhigh |
| Pstack judgment, prose, why synthesis, reflect synthesis, independent-family review | anthropic/claude-opus-5-5 | high |
| Hardest ambiguous design, cross-cutting architecture, unresolved high-stakes problems | bifrost/azure/gpt-6-astra | high |
| Terminal-heavy escalation only when Sol is inadequate | bifrost/azure/gpt-6-astra | xhigh |

Use explicit model and effort on delegated calls. No Haiku unless the user explicitly requests it. Do not use Explore for auditing or open-ended analysis. Do not delegate a known-path lookup that a direct tool can answer.

Prefer medium for coding even though high has a higher general Intelligence Index score. On the current Coding Agent Index, medium dominates high and max. Escalate to xhigh when complexity or observed failure warrants it, not on every call. Retain Luna xhigh per the existing user preference; its low terminal success means it is not a substitute for Sol on autonomous engineering.

No max by default. Sonnet and Astra remain available for explicit selection; neither is the routine coding route. Opus is selected for pstack judgment and synthesis. The hardest ambiguous design role uses Astra high by explicit user preference on 2026-09-29; this overrides the benchmark-derived choice and is not a claim that Astra high is Pareto-optimal. Opus high/xhigh/max levels occupy the candidate general-intelligence frontier and exceed Sol on SciCode; that does not prove superiority on every design or prose task. This explicitly trades cost for capability, rather than claiming lower coding cost. User-selected model cycling order in Pi and Prime is Luna → Sonnet → Sol → Opus → Fable → Astra. Fable is included in cycling by explicit user preference; this does not change delegated role routing.

## Evidence

| Model / effort | AA Intelligence Index | Intelligence cost/task | Coding Agent Index | Coding cost/task |
| --- | ---: | ---: | ---: | ---: |
| GPT-6.1 Sol low | 42.1 | $0.131 | 57.2 | $0.499 |
| GPT-6.1 Sol medium | 47.8 | $0.214 | 61.4 | $0.705 |
| GPT-6.1 Sol high | 50.2 | $0.319 | 60.1 | $0.889 |
| GPT-6.1 Sol xhigh | 51.0 | $0.393 | 62.9 | $1.040 |
| GPT-6.1 Sol max | 51.8 | $0.724 | 60.1 | $1.554 |
| Claude Sonnet 5.5 high | 46.7 | $1.080 | 55.0 | $1.235 |
| Claude Sonnet 5.5 xhigh | 51.9 | $2.743 | 62.9 | $3.333 |
| GPT-6 Luna xhigh | 33.9 | $0.042 | not reported | not reported |
| GPT-6 Luna max | 37.3 | $0.068 | 41.1 | $0.176 |
| Claude Opus 5.5 medium | 51.2 | $1.336 | not reported | not reported |
| Claude Opus 5.5 high | 53.6 | $1.823 | not reported | not reported |
| Claude Opus 5.5 xhigh | 56.0 | $3.459 | not reported | not reported |
| Claude Opus 5.5 max | 57.6 | $5.982 | 66.0 | $13.036 |

Sources:
- https://artificialanalysis.ai/models/gpt-6-1-sol-high
- https://artificialanalysis.ai/models/gpt-6-1-sol-medium
- https://artificialanalysis.ai/models/gpt-6-1-sol-xhigh
- https://artificialanalysis.ai/models/claude-sonnet-5-5-high
- https://artificialanalysis.ai/models/claude-opus-5-5-high
- https://artificialanalysis.ai/models/claude-opus-5-5-xhigh
- https://artificialanalysis.ai/agents/coding-agents
- https://artificialanalysis.ai/methodology/coding-agents-benchmarking

The machine-readable snapshot is ~/.codex/aa-frontier-2026-09-29.json. Coding scores include the agent harness: Codex for GPT and Claude Code for Claude. They are evidence for initial routing, not measured Pi success rates or proof of universal refactoring superiority. Cost divided by benchmark pass@1 is a descriptive cost-per-success proxy, not a guarantee about independent retries.

## Harness behavior

Pi uses ~/.pi/agent/settings.json modelThinkingLevels for per-model startup effort. The custom Explore and Plan overrides passed live tests, then the user explicitly removed them in another Pi session. Respect those removals. Embedded Explore again pins Haiku; a call-site model cannot override that pin, so route bounded lookup through direct tools or general-purpose with explicit Luna/xhigh instead. This is an orchestration no-Haiku policy, not a claim that every catalog entry is blocked. General-purpose and pstack agents stay unpinned so per-call routes and panel diversity remain possible. New default sessions inherit Sol/medium.

Pi is the primary harness, and pstack's Pi integration and ~/.pi/agent/pstack-models.md are Pi-only. Prime is an experiment, not a pstack optimization target. Do not share the Pi role profile with experimental harnesses or adapt pstack to their native APIs.

Codex native subagents use only the confirmed GPT slugs here; do not pretend they can use Opus. Its profile remains GPT-only, while Pi panels retain an Opus family.

Pstack role profiles are not executable routing tables: skills must read them before spawning. All roles are explicitly listed so stale bundled defaults are not used. Claude Code can only use Claude aliases in its native Agent tool; use Pi/Codex when requesting Sol refactoring instead of inventing a cross-provider alias.

Reload Pi to refresh agent descriptions and settings. Resuming Pi retains the session's recorded model/effort unless explicitly overridden.
