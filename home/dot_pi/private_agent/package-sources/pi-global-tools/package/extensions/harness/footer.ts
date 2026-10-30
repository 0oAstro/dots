import { SettingsManager, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { basename } from "node:path";
import { hostname, userInfo } from "node:os";

const RESET_FG = "\x1b[39m";
const BOLD = "\x1b[1m";
const RESET_BOLD = "\x1b[22m";

const COLOR = {
	grey: "\x1b[90m",
	white: "\x1b[37m",
	red: "\x1b[31m",
	yellow: "\x1b[33m",
	blue: "\x1b[34m",
	magenta: "\x1b[35m",
	cyan: "\x1b[36m",
	orange: "\x1b[38;5;19m",
};

const ICON = {
	model: "\ueb08",
	thinking: "\uf0eb",
	input: "\uf019",
	output: "\uf093",
	cache: "\uf1c0",
	ttft: "\uf017",
	speed: "\uf0e7",
	context: "\uf2db",
	autoCompact: "\uf021",
	groupSeparator: "\ue0b1",
};

const DURATION_THRESHOLD_MS = 5000;
const WORKING_FRAME_MS = 400;
const WORKING_DOTS = ["...", "..", "."];
const GIT_DEBOUNCE_MS = 250;
const GIT_TIMEOUT_MS = 3000;
const REQUIRED = Number.POSITIVE_INFINITY;

type Zone = "left" | "right";
type Group = "activity" | "workspace" | "model" | "usage" | "performance" | "context";

const GROUP_JOINER: Record<Group, string> = {
	activity: " ",
	workspace: " ",
	model: paint(COLOR.grey, " · "),
	usage: "  ",
	performance: "  ",
	context: " ",
};

const GROUP_SEPARATOR = paint(COLOR.grey, ` ${ICON.groupSeparator} `);

interface Item {
	zone: Zone;
	group: Group;
	full: string;
	compact: string;
	dropRank: number;
}

interface GitState {
	head: string;
	dirty: boolean;
	ahead: boolean;
	behind: boolean;
}

interface UsageTotals {
	key: string;
	input: number;
	output: number;
	cost: number;
	cacheHitPercent: number | undefined;
	contextPercent: number | null;
	contextWindow: number;
}

interface ResponseTiming {
	requestedAt: number;
	firstTokenAt: number | undefined;
	ttftMs: number | undefined;
	tokensPerSecond: number | undefined;
}

function paint(color: string, text: string): string {
	return color + text + RESET_FG;
}

function bold(text: string): string {
	return BOLD + text + RESET_BOLD;
}

function labelled(icon: string, value: string, color: string): string {
	return paint(COLOR.grey, icon) + " " + paint(color, value);
}

function formatTokens(count: number): string {
	if (count < 1000) return `${count}`;
	if (count < 10_000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1_000_000) return `${Math.round(count / 1000)}k`;
	if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
	return `${Math.round(count / 1_000_000)}M`;
}

function formatDuration(ms: number): string {
	let seconds = Math.floor(ms / 1000);
	const days = Math.floor(seconds / 86400);
	seconds -= days * 86400;
	const hours = Math.floor(seconds / 3600);
	seconds -= hours * 3600;
	const minutes = Math.floor(seconds / 60);
	seconds -= minutes * 60;
	let text = "";
	if (days > 0) text += `${days}d `;
	if (days > 0 || hours > 0) text += `${hours}h `;
	if (days > 0 || hours > 0 || minutes > 0) text += `${minutes}m `;
	return text + `${seconds}s`;
}

function formatTtft(ms: number): string {
	if (ms < 1000) return `${Math.round(ms)}ms`;
	return `${(ms / 1000).toFixed(1)}s`;
}

function formatCwd(cwd: string): string {
	const home = process.env.HOME;
	if (home && (cwd === home || cwd.startsWith(home + "/"))) return "~" + cwd.slice(home.length);
	return cwd;
}

function buildHostSegment(): string {
	const user = userInfo().username;
	const host = hostname().split(".")[0];
	if (user === "root") return paint(COLOR.white, user) + paint(COLOR.grey, "@" + host);
	if (process.env.SSH_CONNECTION || process.env.SSH_TTY) return paint(COLOR.grey, `${user}@${host}`);
	return "";
}

const HOST_SEGMENT = buildHostSegment();

function parseGitStatus(stdout: string): GitState | undefined {
	let head = "";
	let oid = "";
	let dirty = false;
	let ahead = false;
	let behind = false;
	for (const line of stdout.split("\n")) {
		if (line.startsWith("# branch.head ")) {
			head = line.slice("# branch.head ".length);
		} else if (line.startsWith("# branch.oid ")) {
			oid = line.slice("# branch.oid ".length);
		} else if (line.startsWith("# branch.ab ")) {
			const parts = line.split(" ");
			ahead = parts[2] !== "+0";
			behind = parts[3] !== "-0";
		} else if (line.length > 0 && !line.startsWith("#")) {
			dirty = true;
		}
	}
	if (!head) return undefined;
	if (head === "(detached)") head = "@" + oid.slice(0, 8);
	return { head, dirty, ahead, behind };
}

function readUsage(ctx: ExtensionContext, cache: UsageTotals | undefined): UsageTotals {
	const sm = ctx.sessionManager;
	const key = `${sm.getSessionId()}:${sm.getLeafId()}:${sm.getEntryCount()}:${ctx.model?.id}`;
	if (cache && cache.key === key) return cache;

	let input = 0;
	let output = 0;
	let cost = 0;
	let cacheHitPercent: number | undefined;
	for (const entry of sm.getEntries()) {
		let usage = undefined;
		if (entry.type === "usage") {
			usage = entry.usage;
		} else if (entry.type === "message" && entry.message.role === "assistant") {
			usage = entry.message.usage;
			const prompt = usage.input + usage.cacheRead + usage.cacheWrite;
			cacheHitPercent = prompt > 0 ? (usage.cacheRead / prompt) * 100 : undefined;
		} else if (entry.type === "message" && entry.message.role === "toolResult") {
			usage = entry.message.usage;
		} else if (entry.type === "branch_summary" || entry.type === "compaction") {
			usage = entry.usage;
		}
		if (!usage) continue;
		input += usage.input;
		output += usage.output;
		cost += usage.cost.total;
	}

	const context = ctx.getContextUsage();
	return {
		key,
		input,
		output,
		cost,
		cacheHitPercent,
		contextPercent: context?.percent ?? null,
		contextWindow: context?.contextWindow ?? ctx.model?.contextWindow ?? 0,
	};
}

function joinZone(items: Item[], zone: Zone, useCompact: boolean): string {
	let text = "";
	let previousGroup: Group | undefined;
	for (const item of items) {
		if (item.zone !== zone) continue;
		const piece = useCompact ? item.compact : item.full;
		if (previousGroup === undefined) text = piece;
		else if (previousGroup === item.group) text += GROUP_JOINER[item.group] + piece;
		else text += GROUP_SEPARATOR + piece;
		previousGroup = item.group;
	}
	return text;
}

function lineWidth(items: Item[], useCompact: boolean): number {
	const left = visibleWidth(joinZone(items, "left", useCompact));
	const right = visibleWidth(joinZone(items, "right", useCompact));
	if (left > 0 && right > 0) return left + 2 + right;
	return left + right;
}

function composeLine(items: Item[], width: number): string {
	let useCompact = false;
	if (lineWidth(items, false) > width) useCompact = true;

	const kept = items.slice();
	if (useCompact) {
		const droppable: Item[] = [];
		for (const item of items) {
			if (item.dropRank !== REQUIRED) droppable.push(item);
		}
		droppable.sort((a, b) => a.dropRank - b.dropRank);
		for (const item of droppable) {
			if (lineWidth(kept, true) <= width) break;
			kept.splice(kept.indexOf(item), 1);
		}
	}

	const left = joinZone(kept, "left", useCompact);
	const right = joinZone(kept, "right", useCompact);
	const gap = width - visibleWidth(left) - visibleWidth(right);
	if (left && right && gap >= 2) return left + " ".repeat(gap) + right;
	return truncateToWidth(left || right, width, "…");
}

export function footer(pi: ExtensionAPI) {
	let git: GitState | undefined;
	let gitTimer: ReturnType<typeof setTimeout> | undefined;
	let gitRunning = false;
	let gitPending = false;
	let runStartedAt: number | undefined;
	let lastRunMs = 0;
	let frameTimer: ReturnType<typeof setInterval> | undefined;
	let frameIndex = 0;
	let usageCache: UsageTotals | undefined;
	let timing: ResponseTiming | undefined;
	let autoCompact = false;
	let requestRender: (() => void) | undefined;
	let activeCtx: ExtensionContext | undefined;

	async function refreshGit(): Promise<void> {
		if (!activeCtx) return;
		if (gitRunning) {
			gitPending = true;
			return;
		}
		gitRunning = true;
		try {
			const result = await pi.exec(
				"git",
				["--no-optional-locks", "status", "--porcelain=v2", "--branch"],
				{ cwd: activeCtx.cwd, timeout: GIT_TIMEOUT_MS },
			);
			git = result.code === 0 ? parseGitStatus(result.stdout) : undefined;
		} catch {
			git = undefined;
		}
		gitRunning = false;
		requestRender?.();
		if (gitPending) {
			gitPending = false;
			scheduleGit();
		}
	}

	function scheduleGit(): void {
		if (gitTimer) clearTimeout(gitTimer);
		gitTimer = setTimeout(() => {
			gitTimer = undefined;
			void refreshGit();
		}, GIT_DEBOUNCE_MS);
	}

	function stopFrameTimer(): void {
		if (frameTimer) clearInterval(frameTimer);
		frameTimer = undefined;
		frameIndex = 0;
	}

	function activityItem(): Item {
		if (runStartedAt === undefined) {
			const ready = paint(COLOR.blue, bold("● READY"));
			return { zone: "left", group: "activity", full: ready, compact: ready, dropRank: REQUIRED };
		}
		const label = "● WORKING";
		const dots = WORKING_DOTS[frameIndex].padEnd(3, " ");
		return {
			zone: "left",
			group: "activity",
			full: paint(COLOR.orange, bold(label + dots)),
			compact: paint(COLOR.orange, bold(label)),
			dropRank: REQUIRED,
		};
	}

	function workspaceItems(ctx: ExtensionContext, fallbackBranch: string | null): Item[] {
		const items: Item[] = [];
		if (HOST_SEGMENT) {
			items.push({ zone: "left", group: "workspace", full: HOST_SEGMENT, compact: HOST_SEGMENT, dropRank: 30 });
		}

		const path = formatCwd(ctx.cwd);
		items.push({
			zone: "left",
			group: "workspace",
			full: paint(COLOR.blue, path),
			compact: paint(COLOR.blue, basename(path) || path),
			dropRank: REQUIRED,
		});

		const head = git?.head ?? fallbackBranch;
		if (head) {
			const dirty = git?.dirty ? "*" : "";
			let arrows = "";
			if (git?.behind) arrows += "⇣";
			if (git?.ahead) arrows += "⇡";
			const arrowText = arrows ? " " + paint(COLOR.cyan, arrows) : "";
			items.push({
				zone: "left",
				group: "workspace",
				full: paint(COLOR.grey, head + dirty) + arrowText,
				compact: paint(COLOR.grey, truncateToWidth(head, 18, "…") + dirty) + arrowText,
				dropRank: 65,
			});
		}

		let elapsed = lastRunMs;
		if (runStartedAt !== undefined) elapsed = Date.now() - runStartedAt;
		if (elapsed >= DURATION_THRESHOLD_MS) {
			const duration = paint(COLOR.yellow, formatDuration(elapsed));
			items.push({ zone: "left", group: "workspace", full: duration, compact: duration, dropRank: 52 });
		}
		return items;
	}

	function modelItems(ctx: ExtensionContext): Item[] {
		const model = ctx.model;
		if (!model) return [];
		const shortId = model.id.slice(model.id.lastIndexOf("/") + 1);
		const items: Item[] = [
			{
				zone: "left",
				group: "model",
				full: paint(COLOR.magenta, ICON.model) + " " + bold(model.id),
				compact: paint(COLOR.magenta, ICON.model) + " " + bold(truncateToWidth(shortId, 24, "…")),
				dropRank: 60,
			},
		];
		if (model.reasoning) {
			const level = pi.getThinkingLevel();
			const color = level === "off" ? COLOR.grey : COLOR.magenta;
			const text = paint(color, ICON.thinking) + " " + paint(COLOR.grey, level);
			items.push({ zone: "left", group: "model", full: text, compact: text, dropRank: 10 });
		}
		return items;
	}

	function usageItems(usage: UsageTotals): Item[] {
		const items: Item[] = [];
		if (usage.input > 0 || usage.output > 0) {
			const input = labelled(ICON.input, formatTokens(usage.input), COLOR.blue);
			const output = labelled(ICON.output, formatTokens(usage.output), COLOR.magenta);
			items.push({ zone: "right", group: "usage", full: input, compact: input, dropRank: 40 });
			items.push({ zone: "right", group: "usage", full: output, compact: output, dropRank: 40 });
		}
		if (usage.cacheHitPercent !== undefined) {
			const cache = labelled(ICON.cache, `${Math.round(usage.cacheHitPercent)}%`, COLOR.cyan);
			items.push({ zone: "right", group: "usage", full: cache, compact: cache, dropRank: 50 });
		}
		if (usage.cost > 0) {
			const cost = paint(COLOR.orange, `$${usage.cost.toFixed(2)}`);
			items.push({ zone: "right", group: "usage", full: cost, compact: cost, dropRank: 20 });
		}
		return items;
	}

	function performanceItems(): Item[] {
		if (timing?.ttftMs === undefined) return [];
		let text = labelled(ICON.ttft, formatTtft(timing.ttftMs), COLOR.magenta);
		if (timing.tokensPerSecond !== undefined) {
			text += "  " + labelled(ICON.speed, timing.tokensPerSecond.toFixed(1), COLOR.magenta);
			text += paint(COLOR.grey, "/s");
		}
		return [{ zone: "right", group: "performance", full: text, compact: text, dropRank: 45 }];
	}

	function contextItem(usage: UsageTotals): Item {
		const percent = usage.contextPercent;
		let color = COLOR.blue;
		if (percent !== null && percent >= 90) color = COLOR.red;
		else if (percent !== null && percent >= 70) color = COLOR.yellow;
		const percentText = percent === null ? "?" : `${percent.toFixed(1)}%`;
		const compact = paint(color, ICON.context) + " " + paint(color, percentText);
		let full = compact;
		if (usage.contextWindow > 0) full += paint(COLOR.grey, ` / ${formatTokens(usage.contextWindow)}`);
		if (autoCompact) full += " " + paint(COLOR.grey, ICON.autoCompact);
		return { zone: "right", group: "context", full, compact, dropRank: REQUIRED };
	}

	function renderStatusLine(ctx: ExtensionContext, fallbackBranch: string | null, width: number): string {
		usageCache = readUsage(ctx, usageCache);
		const items: Item[] = [activityItem()];
		items.push(...workspaceItems(ctx, fallbackBranch));
		items.push(...modelItems(ctx));
		items.push(...usageItems(usageCache));
		items.push(...performanceItems());
		items.push(contextItem(usageCache));
		return composeLine(items, width);
	}

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		activeCtx = ctx;
		usageCache = undefined;
		timing = undefined;
		git = undefined;
		autoCompact = SettingsManager.create(ctx.cwd).getCompactionSettings().enabled;
		ctx.ui.setFooter((tui, _theme, footerData) => {
			requestRender = () => tui.requestRender();
			const unsubscribeBranch = footerData.onBranchChange(() => {
				scheduleGit();
				tui.requestRender();
			});
			return {
				dispose() {
					unsubscribeBranch();
					requestRender = undefined;
				},
				invalidate() {},
				render(width: number): string[] {
					const lines = [renderStatusLine(ctx, footerData.getGitBranch(), width)];
					const statuses = footerData.getExtensionStatuses();
					if (statuses.size > 0) {
						const keys = Array.from(statuses.keys()).sort();
						const texts: string[] = [];
						for (const key of keys) {
							const text = statuses.get(key);
							if (text) texts.push(text.replace(/[\r\n\t]+/g, " ").trim());
						}
						lines.push(truncateToWidth(texts.join(" "), width, "…"));
					}
					return lines;
				},
			};
		});
		void refreshGit();
	});

	pi.on("agent_start", () => {
		if (runStartedAt !== undefined) return;
		runStartedAt = Date.now();
		lastRunMs = 0;
		stopFrameTimer();
		frameTimer = setInterval(() => {
			frameIndex = (frameIndex + 1) % WORKING_DOTS.length;
			requestRender?.();
		}, WORKING_FRAME_MS);
		requestRender?.();
	});

	pi.on("before_provider_request", () => {
		timing = { requestedAt: Date.now(), firstTokenAt: undefined, ttftMs: undefined, tokensPerSecond: undefined };
	});

	pi.on("message_update", (event) => {
		if (!timing || timing.firstTokenAt !== undefined) return;
		if (event.message.role !== "assistant") return;
		timing.firstTokenAt = Date.now();
		timing.ttftMs = timing.firstTokenAt - timing.requestedAt;
		requestRender?.();
	});

	pi.on("message_end", (event) => {
		if (event.message.role !== "assistant") return;
		if (!timing || timing.firstTokenAt === undefined) return;
		const generationMs = Date.now() - timing.firstTokenAt;
		const outputTokens = event.message.usage.output;
		if (generationMs > 0 && outputTokens > 0) timing.tokensPerSecond = outputTokens / (generationMs / 1000);
		requestRender?.();
	});

	pi.on("turn_end", () => {
		scheduleGit();
	});

	pi.on("agent_settled", () => {
		if (runStartedAt !== undefined) lastRunMs = Date.now() - runStartedAt;
		runStartedAt = undefined;
		stopFrameTimer();
		scheduleGit();
		requestRender?.();
	});

	pi.on("input", () => {
		scheduleGit();
	});

	pi.on("session_shutdown", () => {
		if (gitTimer) clearTimeout(gitTimer);
		gitTimer = undefined;
		stopFrameTimer();
		activeCtx = undefined;
		requestRender = undefined;
	});
}
