import { execFile } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const SHOW_AFTER_MS = 4000;
const FRAME_MS = 250;
const BREATH_PHASE_MS = 4000;
const PROMPT_CHANGE_MS = 30000;
const ROWS_KEPT_FOR_EDITOR_AND_FOOTER = 8;
const WIDGET_KEY = "detox";

const BREATH_PHASES = ["breathe in", "hold", "breathe out", "hold"];

const THINK_PROMPTS = [
	"What do you expect the answer to be?",
	"How would you do this yourself?",
	"What is the most likely way this goes wrong?",
	"How will you check that the result is right?",
	"What did you forget to tell the agent?",
	"Look away from the screen. Look at something far away.",
];

function formatElapsed(ms: number): string {
	const totalSeconds = Math.floor(ms / 1000);
	const minutes = Math.floor(totalSeconds / 60);
	const seconds = totalSeconds % 60;
	return `${minutes}:${String(seconds).padStart(2, "0")}`;
}

function breathBar(elapsedMs: number, barWidth: number): { bar: string; phase: string } {
	const phaseIndex = Math.floor(elapsedMs / BREATH_PHASE_MS) % BREATH_PHASES.length;
	const phaseProgress = (elapsedMs % BREATH_PHASE_MS) / BREATH_PHASE_MS;
	let fill = 0;
	if (phaseIndex === 0) fill = phaseProgress;
	if (phaseIndex === 1) fill = 1;
	if (phaseIndex === 2) fill = 1 - phaseProgress;
	const filled = Math.round(fill * barWidth);
	const bar = "█".repeat(filled) + "·".repeat(barWidth - filled);
	return { bar, phase: BREATH_PHASES[phaseIndex] ?? "" };
}

function centerLine(line: string, width: number): string {
	const leftPad = Math.max(0, Math.floor((width - visibleWidth(line)) / 2));
	return truncateToWidth(" ".repeat(leftPad) + line, width, "");
}

function isFocusedPane(output: string): boolean {
	let parsed: unknown;
	try {
		parsed = JSON.parse(output);
	} catch {
		return false;
	}
	if (typeof parsed !== "object" || parsed === null || !("result" in parsed)) return false;
	const result = parsed.result;
	if (typeof result !== "object" || result === null || !("pane" in result)) return false;
	const pane = result.pane;
	if (typeof pane !== "object" || pane === null || !("focused" in pane)) return false;
	return pane.focused === true;
}

function announceDone(): void {
	const herdrBin = process.env.HERDR_BIN_PATH;
	const paneId = process.env.HERDR_PANE_ID;
	if (process.env.HERDR_ENV !== "1" || !herdrBin || !paneId) {
		process.stdout.write("\x07");
		return;
	}
	execFile(herdrBin, ["pane", "get", paneId], (paneError, paneOutput) => {
		if (paneError || !isFocusedPane(paneOutput)) return;
		execFile(herdrBin, ["notification", "show", "pi is done", "--sound", "done"], (error) => {
			if (error) process.stdout.write("\x07");
		});
	});
}

export default function (pi: ExtensionAPI) {
	let enabled = true;
	let runActive = false;
	let coverShown = false;
	let runStartedAt = 0;
	let showTimer: ReturnType<typeof setTimeout> | undefined;
	let firstPromptIndex = 0;

	function clearShowTimer(): void {
		if (showTimer) clearTimeout(showTimer);
		showTimer = undefined;
	}

	function showCover(ctx: ExtensionContext): void {
		coverShown = true;
		ctx.ui.setWidget(WIDGET_KEY, (tui, theme) => {
			const frameTimer = setInterval(() => tui.requestRender(), FRAME_MS);
			return {
				render(width: number): string[] {
					const height = Math.max(6, tui.terminal.rows - ROWS_KEPT_FOR_EDITOR_AND_FOOTER);
					const elapsedMs = Date.now() - runStartedAt;
					const barWidth = Math.max(10, Math.min(40, width - 4));
					const breath = breathBar(elapsedMs, barWidth);
					const promptIndex = (firstPromptIndex + Math.floor(elapsedMs / PROMPT_CHANGE_MS)) % THINK_PROMPTS.length;
					const body = [
						theme.fg("muted", `agent working  ${formatElapsed(elapsedMs)}`),
						"",
						theme.fg("accent", breath.bar),
						theme.bold(breath.phase),
						"",
						theme.fg("dim", THINK_PROMPTS[promptIndex] ?? ""),
					];
					const lines: string[] = [];
					const topPad = Math.max(0, Math.floor((height - body.length) / 2));
					for (let i = 0; i < topPad; i++) lines.push("");
					for (const line of body) lines.push(centerLine(line, width));
					while (lines.length < height) lines.push("");
					return lines.slice(0, height);
				},
				invalidate(): void {},
				dispose(): void {
					clearInterval(frameTimer);
				},
			};
		});
	}

	function hideCover(ctx: ExtensionContext): void {
		if (!coverShown) return;
		coverShown = false;
		ctx.ui.setWidget(WIDGET_KEY, undefined);
	}

	pi.registerCommand("detox", {
		description: "Cover the agent stream while it works: /detox on | off",
		handler: async (args, ctx) => {
			const arg = args.trim();
			if (arg === "off") enabled = false;
			if (arg === "on") enabled = true;
			if (!enabled) hideCover(ctx);
			ctx.ui.setStatus("detox", enabled ? undefined : "detox off");
			ctx.ui.notify(`Detox is ${enabled ? "on" : "off"}.`, "info");
		},
	});

	pi.on("agent_start", (_event, ctx) => {
		if (ctx.mode !== "tui" || !enabled || runActive) return;
		runActive = true;
		runStartedAt = Date.now();
		firstPromptIndex = Math.floor(Math.random() * THINK_PROMPTS.length);
		clearShowTimer();
		showTimer = setTimeout(() => {
			if (runActive && enabled) showCover(ctx);
		}, SHOW_AFTER_MS);
	});

	pi.on("ui_prompt_start", (_event, ctx) => {
		clearShowTimer();
		hideCover(ctx);
	});

	pi.on("ui_prompt_end", (_event, ctx) => {
		if (runActive && enabled) showCover(ctx);
	});

	pi.on("agent_settled", (event, ctx) => {
		if (!runActive) return;
		runActive = false;
		clearShowTimer();
		const wasShown = coverShown;
		hideCover(ctx);
		if (wasShown && !event.aborted) announceDone();
	});

	pi.on("session_shutdown", () => {
		clearShowTimer();
		runActive = false;
		coverShown = false;
	});
}
