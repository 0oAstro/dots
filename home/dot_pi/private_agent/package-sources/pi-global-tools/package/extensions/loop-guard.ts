import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const NUDGE_AT = 3;
const STOP_AT = 6;

export default function (pi: ExtensionAPI) {
	let lastCallKey = "";
	let lastResultKey = "";
	let repeatCount = 0;

	pi.on("agent_start", () => {
		lastCallKey = "";
		lastResultKey = "";
		repeatCount = 0;
	});

	pi.on("turn_end", (event, ctx) => {
		const message = event.message;
		if (message.role !== "assistant") return;

		const calls = [];
		for (const part of message.content) {
			if (part.type === "toolCall") calls.push([part.name, part.arguments]);
		}
		if (calls.length === 0) {
			repeatCount = 0;
			return;
		}

		const results = [];
		for (const result of event.toolResults) results.push(result.content);
		const callKey = JSON.stringify(calls);
		const resultKey = JSON.stringify(results);

		if (callKey === lastCallKey && resultKey === lastResultKey) {
			repeatCount += 1;
		} else {
			repeatCount = 1;
		}
		lastCallKey = callKey;
		lastResultKey = resultKey;

		if (repeatCount >= STOP_AT) {
			ctx.abort();
			return {
				entries: [
					{
						type: "custom_message",
						customType: "loop-guard",
						content: `Loop guard stopped the run: the same tool calls returned the same results ${repeatCount} times in a row. Send a new instruction to continue.`,
						display: true,
					},
				],
			};
		}

		if (repeatCount === NUDGE_AT) {
			return {
				entries: [
					{
						type: "custom_message",
						customType: "loop-guard",
						content: `<system-reminder>You issued the same tool calls ${repeatCount} times in a row and got the same results. Review those results and change the arguments or the approach before you continue.</system-reminder>`,
						display: false,
					},
				],
			};
		}
	});
}
