import { readFileSync } from "node:fs";
import { join } from "node:path";
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SETTINGS_KEY = "harness";

type HarnessSettings = {
	loopGuard?: { nudgeAt: number; stopAt: number };
	directToolModels?: string[];
};

function readSettings(): HarnessSettings {
	const settingsPath = join(getAgentDir(), "settings.json");
	const settings = JSON.parse(readFileSync(settingsPath, "utf8"));
	const section = settings[SETTINGS_KEY];
	if (section === undefined) return {};
	if (!section || typeof section !== "object" || Array.isArray(section)) {
		throw new Error(`${SETTINGS_KEY} in ${settingsPath} must be an object.`);
	}
	const loopGuard = section.loopGuard;
	if (loopGuard !== undefined && !(Number.isInteger(loopGuard.nudgeAt) && Number.isInteger(loopGuard.stopAt))) {
		throw new Error(`${SETTINGS_KEY}.loopGuard in ${settingsPath} needs integer nudgeAt and stopAt.`);
	}
	const directToolModels = section.directToolModels;
	if (directToolModels !== undefined && !(Array.isArray(directToolModels) && directToolModels.every((id) => typeof id === "string"))) {
		throw new Error(`${SETTINGS_KEY}.directToolModels in ${settingsPath} must be a list of provider/model strings.`);
	}
	return section;
}

export default function (pi: ExtensionAPI) {
	let settings: HarnessSettings = {};
	let lastCallKey = "";
	let lastResultKey = "";
	let repeatCount = 0;
	let codemodeWasActive = false;

	pi.on("session_start", () => {
		settings = readSettings();
	});

	pi.on("before_agent_start", (_event, ctx) => {
		const directToolModels = settings.directToolModels;
		if (!directToolModels || !ctx.model) return;
		const modelKey = `${ctx.model.provider}/${ctx.model.id}`;
		const active = pi.getActiveTools();
		const hasCodemode = active.includes("codemode");

		if (directToolModels.includes(modelKey)) {
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

	pi.on("agent_start", () => {
		lastCallKey = "";
		lastResultKey = "";
		repeatCount = 0;
	});

	pi.on("turn_end", (event, ctx) => {
		const loopGuard = settings.loopGuard;
		const message = event.message;
		if (!loopGuard || message.role !== "assistant") return;

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

		if (repeatCount >= loopGuard.stopAt) {
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

		if (repeatCount === loopGuard.nudgeAt) {
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
