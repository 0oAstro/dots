# Model routing

Choose delegated models from the rules below. Optimize cost per successful task. GPT-6.1 Sol is the target, not GPT-6 Sol.

For native children use rlm.spawn(..., name=..., model="bifrost/azure/gpt-6.1-sol", thinking="medium") for coding, refactoring, tests and investigation. Always pass model and thinking deliberately. Use thinking="xhigh" for difficult design/refactoring or observed failures, and "high" for non-coding synthesis/judgment. No Haiku unless explicitly requested.

Bounded file/symbol lookup or structured extraction may use model="bifrost/azure/gpt-6-luna", thinking="xhigh". Do not use Luna for open-ended root-cause analysis, architecture review or autonomous refactoring. A known path should use a direct REPL operation instead of a child.

Use anthropic/claude-opus-5-5 at high for judgment and prose. Retain an independent-family review seat when available. Keep routine coding and refactoring on Sol 6.1 medium. No max by default. CLI and restored session effort win over startup and cycling defaults.
