import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export function directTools(pi: ExtensionAPI, models: string[]) {
	let codemodeWasActive = false;

	pi.on("before_agent_start", (_event, ctx) => {
		if (!ctx.model) return;
		const modelKey = `${ctx.model.provider}/${ctx.model.id}`;
		const active = pi.getActiveTools();
		const hasCodemode = active.includes("codemode");

		if (models.includes(modelKey)) {
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
