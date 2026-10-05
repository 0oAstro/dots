import {
	createCodemodeExtension,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	let mode: "on" | "only" = "on";

	createCodemodeExtension({
		get mode() {
			return mode;
		},
	})(pi);

	const syncMode = (_event: unknown, ctx: ExtensionContext) => {
		const next = /(^|\/)gpt(?:[-_.]|$)/i.test(ctx.model?.id ?? "") ? "only" : "on";
		if (mode === next) return;
		mode = next;
		pi.setActiveTools(pi.getActiveTools());
	};

	pi.on("session_start", syncMode);
	pi.on("model_select", syncMode);
	pi.on("before_agent_start", syncMode);
}
