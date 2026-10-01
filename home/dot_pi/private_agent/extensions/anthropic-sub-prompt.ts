import { execSync } from "node:child_process";
import { createHash, randomUUID } from "node:crypto";
import { release } from "node:os";
import { basename } from "node:path";
import fs from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { Api, AssistantMessageEventStream, Context, Model, SimpleStreamOptions } from "@earendil-works/pi-ai";

// Only the built-in anthropic provider with a resolved subscription credential is overlaid.
// All other requests continue through pi's unmodified provider and transport.
const PREAMBLE = "You help users with software engineering tasks by reading files, running commands, and editing code.";
const DUPLICATED = [
 "Use edit for precise changes", "When changing multiple separate locations", "Each edits[].oldText",
 "Keep edits[].oldText", "For broad codebase exploration", "When an agent runs in the background",
 "Trust but verify", "Use SubagentWorkflow when", "Prefer `pipeline`", "A workflow runs in the background",
 "Use ask_user_question whenever", "Each question MUST", "Set multiSelect", "process tool: after process start",
 "process tool: attention", "process tool: use notify.logMatches", "process tool: for the full lifecycle",
 "Task status is a 4-state", "To change a task's status", "Use blockedBy", "list hides tombstoned",
];
const NOTIFY_RULE = "Background agents, workflows and processes notify you when they finish; do not poll or sleep waiting for them.";
function rules(selectedTools: string[], toolGuidelines: Record<string, string[]>): string {
 const out = new Set<string>();
 if (selectedTools.includes("bash")) out.add("Use bash for file operations like ls, rg, find");
 for (const tool of selectedTools) for (const rule of toolGuidelines[tool] ?? [])
  if (!DUPLICATED.some(prefix => rule.startsWith(prefix))) out.add(rule.replace(/^process tool: use/, "Use").trim());
 if (["Agent", "workflow", "process"].some(tool => selectedTools.includes(tool))) out.add(NOTIFY_RULE);
 out.add("Be concise in your responses"); out.add("Show file paths clearly when working with files");
 return [...out].map(rule => `- ${rule}`).join("\n");
}
function isGitRepo(cwd: string): boolean {
 try { execSync("git rev-parse --is-inside-work-tree", { cwd, stdio: "ignore" }); return true; }
 catch { return false; }
}

// omp main: packages/ai/src/providers/claude-code-fingerprint.ts (Claude Code CLI wire identity).
const CC_VERSION = "2.1.280";
const CC_IDENTITY = "You are Claude Code, Anthropic's official CLI for Claude.";
// omp main: packages/ai/src/providers/claude-code-fingerprint.ts (@anthropic-ai/sdk bundled by CC).
const SDK_VERSION = "0.112.1";
// Measured against Claude Code 2.1.284 on claude-opus-5-5: CC sends the model's full ceiling
// (128000), not a 64k clamp. omp's 64k came from Cowork's desktop profile and does not describe
// the CLI, so no output-token clamp is applied here.
// omp main: packages/ai/src/providers/anthropic.ts claudeCodeAgentBetaDefaults (exactly those
// entries, in that order). `advanced-tool-use-2025-11-20` was in omp 17.4.2's Cowork profile and
// was REMOVED upstream; do not re-add it here. `fallback-credit-2026-06-01` is appended by omp at
// request time (buildCoworkBetas), not part of the default profile, so it is appended below too.
const CC_BETAS = ["claude-code-20250219", "oauth-2025-04-20", "interleaved-thinking-2025-05-14",
 "thinking-token-count-2026-05-13", "context-management-2025-06-27", "prompt-caching-scope-2026-01-05",
 "mid-conversation-system-2026-04-07"];
const FALLBACK_CREDIT_BETA = "fallback-credit-2026-06-01";
// omp main: packages/ai/src/providers/anthropic.ts, Claude Code Stainless SDK header set.
const STAINLESS: Record<string, string> = {
 "x-stainless-arch": ({ x64: "x64", arm64: "arm64", ia32: "x86" } as Record<string, string>)[process.arch] ?? `other::${process.arch}`,
 "x-stainless-lang": "js", "x-stainless-os": process.platform === "linux" ? "Linux" : process.platform === "darwin" ? "MacOS" : process.platform === "win32" ? "Windows" : process.platform === "freebsd" ? "FreeBSD" : `Other::${process.platform}`,
 "x-stainless-package-version": SDK_VERSION, "x-stainless-retry-count": "0", "x-stainless-runtime": "node",
 "x-stainless-runtime-version": "v26.3.0", "x-stainless-timeout": "600",
};
// omp main: packages/ai/src/providers/anthropic.ts, cch=00000 is replaced after SDK serialization.
const BILLING_PREFIX = "x-anthropic-billing-header:";
const PLACEHOLDER = "cch=00000";
const MARKER = `"system":[{"type":"text","text":"${BILLING_PREFIX}`;
const CCH_SEED = 0x4d659218e32a3268n;
const SEARCH_WINDOW = 150;
const MASK = 0xffffffffffffffffn;
// Canonical XXH64 primes, pure Node replacement for omp's Bun.hash.xxHash64.
const P1 = 0x9e3779b185ebca87n, P2 = 0xc2b2ae3d27d4eb4fn, P3 = 0x165667b19e3779f9n,
 P4 = 0x85ebca77c2b2ae63n, P5 = 0x27d4eb2f165667c5n;
const u64 = (v: bigint) => v & MASK;
const rotl = (v: bigint, r: bigint) => u64((v << r) | (v >> (64n - r)));
function round(acc: bigint, v: bigint): bigint { return u64(rotl(u64(acc + u64(v * P2)), 31n) * P1); }
function merge(acc: bigint, v: bigint): bigint { return u64(u64((acc ^ round(0n, v)) * P1) + P4); }
function xxh64(bytes: Uint8Array, seed: bigint): bigint {
 const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
 let p = 0, h: bigint;
 if (bytes.length >= 32) {
  let a = u64(seed + P1 + P2), b = u64(seed + P2), c = u64(seed), d = u64(seed - P1);
  do { a = round(a, view.getBigUint64(p, true)); b = round(b, view.getBigUint64(p + 8, true));
   c = round(c, view.getBigUint64(p + 16, true)); d = round(d, view.getBigUint64(p + 24, true)); p += 32;
  } while (p <= bytes.length - 32);
  h = u64(rotl(a, 1n) + rotl(b, 7n) + rotl(c, 12n) + rotl(d, 18n));
  h = merge(merge(merge(merge(h, a), b), c), d);
 } else h = u64(seed + P5);
 h = u64(h + BigInt(bytes.length));
 while (p + 8 <= bytes.length) { h = u64(rotl(u64(h ^ round(0n, view.getBigUint64(p, true))), 27n) * P1 + P4); p += 8; }
 if (p + 4 <= bytes.length) { h = u64(rotl(u64(h ^ u64(BigInt(view.getUint32(p, true)) * P1)), 23n) * P2 + P3); p += 4; }
 while (p < bytes.length) { h = u64(rotl(u64(h ^ u64(BigInt(bytes[p]) * P5)), 11n) * P1); p++; }
 h = u64(h ^ (h >> 33n)); h = u64(h * P2); h = u64(h ^ (h >> 29n)); h = u64(h * P3);
 return u64(h ^ (h >> 32n));
}
function billingHeader(text: string): string {
 // omp main: anthropic.ts createClaudeBillingHeader, salt and character offsets from CC computeFingerprint.
 const chars = [4, 7, 20].map(i => text[i] ?? "0").join("");
 const suffix = createHash("sha256").update(`59cf53e54c78${chars}${CC_VERSION}`).digest("hex").slice(0, 3);
 return `${BILLING_PREFIX} cc_version=${CC_VERSION}.${suffix}; cc_entrypoint=cli; ${PLACEHOLDER};`;
}
function warn(message: string): void { process.stderr.write(`[anthropic-sub-prompt] ${message}\n`); }
function debug(message: string): void { if (process.env.PI_OMP_DEBUG === "1") warn(message); }
function patch(body: string): { body: string; status: string; hash?: string } {
 if (!body.includes(PLACEHOLDER)) return { body, status: "no-placeholder" };
 const bytes = Buffer.from(body, "utf8");
 const anchor = bytes.indexOf(MARKER);
 const from = anchor + Buffer.byteLength(MARKER);
 const at = anchor < 0 ? -1 : bytes.indexOf(PLACEHOLDER, from);
 if (at < 0 || at - from > SEARCH_WINDOW) return { body, status: "unanchored" };
 const hash = (xxh64(bytes, CCH_SEED) & 0xfffffn).toString(16).padStart(5, "0");
 bytes.write(hash, at + 4, 5, "ascii");
 return { body: bytes.toString("utf8"), status: "patched", hash };
}
type SystemBlock = { type: "text"; text: string; cache_control?: { type: "ephemeral" } };
type WireMessage = { role: string; content: unknown };
type Payload = { system?: SystemBlock[]; messages: WireMessage[]; max_tokens: number; thinking?: unknown;
 context_management?: unknown; betas?: string[]; metadata?: { user_id?: string }; [key: string]: unknown };
function firstUserText(messages: WireMessage[]): string {
 const first = messages.find(m => m.role === "user");
 if (typeof first?.content === "string") return first.content;
 if (Array.isArray(first?.content)) {
  const text = first.content.find((b: unknown): b is { type: string; text: string } =>
   typeof b === "object" && b !== null && "type" in b && b.type === "text" && "text" in b && typeof b.text === "string");
  return text?.text ?? "";
 }
 return "";
}
// omp main: anthropic-identity.ts resolveAnthropicMetadataUserId → generateClaudeJsonUserId. That
// shape is a stable {device_id, session_id, account_uuid?} envelope — NOT the older
// `user_<hex>_account_<uuid>_session_<uuid>` cloak from 17.4.2. omp's own comment on it: a fresh
// random id per request "would inflate the backend session count", so session_id must be the real
// session and device_id must be stable. pi exposes a session id but no install id, so device_id is
// derived once per process (stable across every request and session within a run).
let cachedDeviceId: string | undefined;
function deviceId(): string {
 // omp: device_id = SHA256(domain + "\0" + installId [+ "\0" + accountId]). pi has no install id.
 return (cachedDeviceId ??= createHash("sha256").update("pi-anthropic-sub-device-v1\0").update(process.pid.toString()).digest("hex"));
}
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
// Pure: takes the session id for this request. No module-level request state, so overlapping
// subagent requests cannot cross-contaminate each other's metadata.
function metadataUserId(sessionId: string | undefined): string {
 const user: Record<string, string> = { device_id: deviceId() };
 user.session_id = sessionId && UUID_RE.test(sessionId) ? sessionId.toLowerCase() : randomUUID().toLowerCase();
 return JSON.stringify(user);
}

function fingerprint(payload: Payload, sessionId: string | undefined): Payload {
 const originalUserText = firstUserText(payload.messages);
 const system = Array.isArray(payload.system) ? payload.system : [];
 payload.system = [{ type: "text", text: billingHeader(originalUserText) }, ...system];
 // omp main: anthropic.ts builds CC identity in system[1]. Keep existing trimmed prompt
 // in system[2] until live wire evidence shows it needs relocation.
 if (payload.system[1]?.text !== CC_IDENTITY) warn("unexpected Claude Code identity block");
 // Measured against Claude Code 2.1.284: CC does NOT rename or prefix tool names on OAuth — it
 // sends `Read`/`Bash`/`Edit`/`Write` unchanged. omp's `_` prefix is its own invention, so tool
 // names and every tool_use / tool_addition / tool_removal reference are left exactly as pi built
 // them. pi's own mapping is then a no-op and the agent loop sees the real names.
 payload.betas = [...new Set([...(payload.betas ?? []), ...CC_BETAS, FALLBACK_CREDIT_BETA, ...(payload.thinking ? ["effort-2025-11-24"] : [])])];
 // Measured against Claude Code 2.1.284: CC always sends this alongside adaptive thinking.
 // omp main: anthropic.ts shouldKeepThinkingContext sets the same edit for thinking requests.
 if (payload.thinking && !payload.context_management)
  payload.context_management = { edits: [{ type: "clear_thinking_20251015", keep: "all" }] };
 payload.metadata = { ...payload.metadata, user_id: metadataUserId(sessionId) };
 return payload;
}
function isAnthropicModel(model: Model<Api>): model is Model<"anthropic-messages"> {
 return model.api === "anthropic-messages";
}
function overlay(model: Model<Api>, context: Context, options?: SimpleStreamOptions): AssistantMessageEventStream {
 // Deliberately resolve the key here, after pi's model-runtime.prepareRequest has finished.
 const ai = require("@earendil-works/pi-ai") as {
  streamSimpleAnthropic: (model: Model<"anthropic-messages">, context: Context, options?: SimpleStreamOptions) => AssistantMessageEventStream;
 };
 // This provider registration uses anthropic-messages; model.api is checked for safety.
 if (!isAnthropicModel(model)) throw new Error("Unexpected API for Anthropic provider overlay");
 if (model.provider !== "anthropic" || !options?.apiKey?.includes("sk-ant-oat"))
  return ai.streamSimpleAnthropic(model, context, options);
 const previousPayload = options.onPayload, previousFetch = options.fetch ?? globalThis.fetch;
 const wrappedFetch: typeof fetch = async (input, init) => {
  let outbound = init;
  try {
   if (typeof init?.body === "string") {
    const result = patch(init.body);
    if (result.status === "unanchored") warn("billing placeholder unanchored; sending unattested request");
    // User-Agent is lower-case in pi's SDK defaults; pin at the final fetch boundary.
    const headers = new Headers(init.headers);
    headers.set("user-agent", `claude-cli/${CC_VERSION} (external, cli)`);
    headers.set("x-client-request-id", randomUUID());
    // omp main: anthropic.ts buildAnthropicHeaders, connection and encoding for CLI.
    headers.set("connection", "keep-alive");
    headers.set("accept-encoding", "gzip, deflate, br, zstd");
    for (const [key, value] of Object.entries(STAINLESS)) headers.set(key, value);
    outbound = { ...init, headers, body: result.body };
    if (process.env.PI_OMP_DEBUG === "1") {
     const safe = Object.fromEntries(headers.entries());
     for (const key of ["authorization", "x-api-key", "x-bf-vk"]) delete safe[key];
     debug(`fetch cch=${result.hash ?? "none"} sent=${result.body.match(/cch=([0-9a-f]{5})/)?.[0] ?? "missing"} status=${result.status}`);
     debug(`fetch headers=${JSON.stringify(safe)}`);
     if (process.env.PI_OMP_DUMP) fs.writeFileSync(process.env.PI_OMP_DUMP, JSON.stringify({ headers: safe, body: result.body }, null, 2));
    }
   }
  } catch (error) { warn(`fingerprint patch failed; sending unattested: ${String(error)}`); outbound = init; }
  // Network errors must not trigger a second request.
  const response = await previousFetch(input, outbound);
  if (process.env.PI_OMP_DEBUG === "1" && response.ok && response.body) {
   try {
    void response.clone().text().then(text => {
     for (const match of text.matchAll(/"type":"tool_use","id":"[^"]+","name":"([^"]+)"/g)) debug(`raw SSE tool=${match[1]}`);
    }).catch(() => undefined);
   } catch { /* Debugging must not affect transport. */ }
  }
  return response;
 };
 const stream = ai.streamSimpleAnthropic(model, context, {
  ...options,
  headers: { ...options.headers, ...STAINLESS },
  onPayload: async (original, m) => {
   const updated = (await previousPayload?.(original, m)) ?? original;
   try { return fingerprint(updated as Payload, options?.sessionId); }
   catch (error) { warn(`fingerprint payload failed; sending original: ${String(error)}`); return updated; }
  },
  fetch: wrappedFetch,
 });
 return stream;
}
export default function (pi: ExtensionAPI): void {
 pi.registerProvider("anthropic", { api: "anthropic-messages", streamSimple: overlay });
 pi.on("before_agent_start", (event, ctx) => {
  if (!ctx.model || ctx.model.provider !== "anthropic" || !ctx.modelRegistry.isUsingOAuth(ctx.model)) return;
  const options = event.systemPromptOptions;
  const forced = options.forceSystemPrompt;
  options.forceSystemPrompt = undefined;
  const previous = forced ? ctx.getSystemPrompt() : undefined;
  options.forceSystemPrompt = forced;
  options.customPrompt = `${PREAMBLE}\n\n<rules>\n${rules(options.selectedTools, options.toolGuidelines)}\n</rules>`;
  options.sections.environment = [
   `- Is a git repository: ${isGitRepo(ctx.cwd)}`,
   `- Platform: ${process.platform}, ${basename(process.env.SHELL ?? "sh")}, ${release()}`,
   `- Today's date: ${new Date().toISOString().slice(0, 10)}`,
  ].join("\n");
  if (forced && previous && forced.endsWith(previous)) {
   options.forceSystemPrompt = undefined;
   options.forceSystemPrompt = `${forced.slice(0, -previous.length)}${ctx.getSystemPrompt()}`;
  }
 });
}
