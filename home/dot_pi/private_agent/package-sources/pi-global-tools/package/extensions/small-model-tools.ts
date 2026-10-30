import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DIRECT_TOOL_MODELS = [
	"amazon-bedrock/us.anthropic.claude-haiku-5-5",
	"azure/fw-glm-5.3-flash",
	"azure/deepseek-v4.1-flash",
];

export default function (pi: ExtensionAPI) {
	let codemodeWasActive = false;

	pi.on("before_agent_start", (_event, ctx) => {
		if (!ctx.model) return;
		const modelKey = `${ctx.model.provider}/${ctx.model.id}`;
		const active = pi.getActiveTools();
		const hasCodemode = active.includes("codemode");

		if (DIRECT_TOOL_MODELS.includes(modelKey)) {
			if (!hasCodemode) return;
			codemodeWasActive = true;
			const direct = [];
			for (const name of active) {
				if (name !== "codemode") direct.push(name);
			}
			pi.setActiveTools(direct);
			return;
		}

		if (codemodeWasActive && !hasCodemode) {
			pi.setActiveTools([...active, "codemode"]);
			codemodeWasActive = false;
		}
	});
}
