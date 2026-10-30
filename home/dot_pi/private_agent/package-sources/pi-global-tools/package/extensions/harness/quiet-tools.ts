import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

export function quietTools(pi: ExtensionAPI) {
	pi.registerToolRenderer((_toolName, next) => {
		const base = next();
		return {
			renderShell: base?.renderShell,
			renderCall: base?.renderCall,
			renderResult(result, options, theme, context) {
				if (!options.expanded && !context.isError) {
					return new Text("", 0, 0);
				}
				if (base?.renderResult) {
					return base.renderResult(result, options, theme, context);
				}
				const lines: string[] = [];
				for (const part of result.content) {
					if (part.type === "text") lines.push(theme.fg("toolOutput", part.text));
				}
				return new Text(lines.join("\n"), 0, 0);
			},
		};
	});
}
