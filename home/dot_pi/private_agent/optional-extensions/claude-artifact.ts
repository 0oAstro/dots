import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

const API_BASE = "https://api.anthropic.com/api/frame";
const CREDENTIALS_PATH = join(homedir(), ".claude", ".credentials.json");
const BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

async function readAccessToken(): Promise<string> {
	const raw = await readFile(CREDENTIALS_PATH, "utf8");
	const oauth = JSON.parse(raw).claudeAiOauth;
	if (!oauth?.accessToken) {
		throw new Error("No claude.ai login in ~/.claude/.credentials.json. Run claude and /login.");
	}
	if (oauth.expiresAt < Date.now() + 60_000) {
		throw new Error("The Claude Code token has expired. Run any claude command once to refresh it, then retry.");
	}
	return oauth.accessToken;
}

async function callFrameApi(method: string, path: string, body?: unknown, signal?: AbortSignal) {
	const token = await readAccessToken();
	const headers: Record<string, string> = {
		Authorization: `Bearer ${token}`,
		"anthropic-beta": "oauth-2025-04-20",
		Accept: "application/json",
		"X-Frame-CP": "go",
		"X-Frame-Surface": "code",
		"X-Frame-Platform": "cli",
	};
	if (body !== undefined) {
		headers["Content-Type"] = "application/json";
	}
	const response = await fetch(API_BASE + path, {
		method,
		headers,
		body: body === undefined ? undefined : JSON.stringify(body),
		signal,
	});
	const text = await response.text();
	if (!response.ok) {
		throw new Error(`claude.ai artifact API ${method} ${path} returned HTTP ${response.status}: ${text.slice(0, 500)}`);
	}
	return JSON.parse(text);
}

function slugToViewerId(slug: string): string {
	let value = BigInt("0x" + slug.replace(/-/g, ""));
	let id = "";
	while (value > 0n) {
		const remainder = Number(value % 58n);
		id = BASE58_ALPHABET[remainder] + id;
		value = value / 58n;
	}
	return id;
}

function viewerIdToSlug(id: string): string {
	let value = 0n;
	for (const character of id) {
		const digit = BASE58_ALPHABET.indexOf(character);
		if (digit < 0) {
			throw new Error(`Not an artifact id: ${id}`);
		}
		value = value * 58n + BigInt(digit);
	}
	const hex = value.toString(16).padStart(32, "0");
	return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function viewerUrl(slug: string): string {
	return `https://claude.ai/artifact/${slugToViewerId(slug)}`;
}

function slugFromUrl(url: string): string {
	const last = url.trim().replace(/\/+$/, "").split("/").pop() ?? "";
	if (UUID_PATTERN.test(last)) {
		return last;
	}
	return viewerIdToSlug(last);
}

const publishTool = defineTool({
	name: "claude_artifact_publish",
	label: "Claude artifact",
	description:
		"Publish a self-contained HTML file as a private web page on claude.ai (Shaurya's Claude subscription) and return its link. " +
		"Use it when a chart, dashboard, annotated diff, timeline, or side-by-side comparison is clearer as a page than as terminal text. " +
		"Write one HTML file with all CSS and JavaScript inline: the page cannot load scripts, styles, or data from other hosts. " +
		"Never put secrets, tokens, or env values in the page. " +
		"To update a page, edit the same file and pass the url from the earlier publish; open viewers see the new version, and older versions stay in history. " +
		"New pages are private; Shaurya shares them from claude.ai.",
	parameters: Type.Object({
		path: Type.String({ description: "Path to the HTML file to publish" }),
		title: Type.String({ description: "Page title shown on claude.ai and in share links" }),
		description: Type.Optional(Type.String({ description: "One-line summary of the page" })),
		url: Type.Optional(Type.String({ description: "claude.ai artifact URL to update instead of creating a new page" })),
	}),

	async execute(_toolCallId, params, signal, _onUpdate, ctx) {
		const filePath = resolve(ctx.cwd, params.path);
		const content = await readFile(filePath, "utf8");
		const body: Record<string, unknown> = {
			title: params.title,
			description: params.description ?? params.title,
			content,
			publish_context: "interactive",
			template: "plain",
		};
		if (params.url) {
			body.slug = slugFromUrl(params.url);
		}
		const result = await callFrameApi("POST", "/deploy/direct", body, signal);
		const url = viewerUrl(result.slug);
		const action = params.url ? "Updated" : "Published";
		return {
			content: [{ type: "text", text: `${action} ${url} (version ${result.seq}, private: ${result.public === false})` }],
			details: { url, slug: result.slug, version: result.version, seq: result.seq, title: params.title, path: filePath },
		};
	},
});

export default function (pi: ExtensionAPI) {
	pi.registerTool(publishTool);

	pi.registerCommand("artifacts", {
		description: "List your claude.ai artifacts",
		handler: async (_args, ctx) => {
			const result = await callFrameApi("GET", "/frames?limit=20");
			const lines: string[] = [];
			for (const frame of result.frames ?? []) {
				if (frame.rel !== "mine") {
					continue;
				}
				lines.push(`${frame.updatedAt.slice(0, 16).replace("T", " ")}  ${frame.title}\n  ${viewerUrl(frame.slug)}`);
			}
			ctx.ui.notify(lines.length > 0 ? lines.join("\n") : "No artifacts yet.", "info");
		},
	});
}
