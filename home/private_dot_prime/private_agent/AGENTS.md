# Model routing

Choose delegated models from the rules below. Optimize cost per successful task. GPT-6.1 Sol is the target, not GPT-6 Sol.

For native children use rlm.spawn(..., name=..., model="bifrost/azure/gpt-6.1-sol", thinking="medium") for coding, refactoring, tests and investigation. Always pass model and thinking deliberately. Use thinking="xhigh" for difficult design/refactoring or observed failures, and "high" for non-coding synthesis/judgment.

Bounded file/symbol lookup or structured extraction may use model="bifrost/anthropic/claude-haiku-5-5", thinking="xhigh". Do not use Haiku for open-ended root-cause analysis, architecture review or autonomous refactoring. A known path should use a direct REPL operation instead of a child.

Use anthropic/claude-opus-5-5 at high for judgment and prose. Retain an independent-family review seat when available: bifrost/azure/fw-glm-5.3-flash or bifrost/azure/fw-kimi-k3 at max. Keep routine coding and refactoring on Sol 6.1 medium. No max by default. CLI and restored session effort win over startup and cycling defaults.
