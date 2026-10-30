import { readFileSync } from "node:fs";
import { join } from "node:path";
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { directTools } from "./direct-tools.js";
import { footer } from "./footer.js";
import { loopGuard } from "./loop-guard.js";
import { quietTools } from "./quiet-tools.js";

const SETTINGS_KEY = "harness";

function readSection(): Record<string, unknown> {
	const settingsPath = join(getAgentDir(), "settings.json");
	const settings = JSON.parse(readFileSync(settingsPath, "utf8"));
	const section = settings[SETTINGS_KEY];
	if (section === undefined) return {};
	if (!section || typeof section !== "object" || Array.isArray(section)) {
		throw new Error(`${SETTINGS_KEY} in ${settingsPath} must be an object.`);
	}
	return section;
}

function isPositiveInteger(value: unknown): boolean {
	return Number.isInteger(value) && (value as number) > 0;
}

export default function (pi: ExtensionAPI) {
	const section = readSection();
	const where = `${SETTINGS_KEY} in ${join(getAgentDir(), "settings.json")}`;

	if (section.footer !== undefined) {
		if (typeof section.footer !== "boolean") throw new Error(`${where}: footer must be true or false.`);
		if (section.footer) footer(pi);
	}

	if (section.quietTools !== undefined) {
		if (typeof section.quietTools !== "boolean") throw new Error(`${where}: quietTools must be true or false.`);
		if (section.quietTools) quietTools(pi);
	}

	if (section.loopGuard !== undefined) {
		const settings = section.loopGuard as { nudgeAt: unknown; stopAt: unknown };
		if (!isPositiveInteger(settings.nudgeAt) || !isPositiveInteger(settings.stopAt)) {
			throw new Error(`${where}: loopGuard needs positive integer nudgeAt and stopAt.`);
		}
		loopGuard(pi, settings as { nudgeAt: number; stopAt: number });
	}

	if (section.directToolModels !== undefined) {
		const models = section.directToolModels;
		if (!Array.isArray(models) || !models.every((id) => typeof id === "string")) {
			throw new Error(`${where}: directToolModels must be a list of provider/model strings.`);
		}
		if (models.length > 0) directTools(pi, models);
	}
}
