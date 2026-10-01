import assert from "node:assert/strict";
import path from "node:path";
import * as sdk from "@earendil-works/pi-coding-agent";
import { discoverAgents } from "../npm/node_modules/pi-subagents/src/agents/agents.js";
import { resolvePiLaunchToolPlan } from "../npm/node_modules/pi-subagents/src/runs/shared/child-tool-plan.js";
import { createDefaultChildSessionFactory } from "../npm/node_modules/pi-subagents/src/runs/shared/child-session.js";
import { CHILD_SUBAGENT_BOUNDARY_INSTRUCTIONS } from "../npm/node_modules/pi-subagents/src/runs/shared/subagent-prompt-runtime.js";

const extensionPath = path.resolve(import.meta.dirname, "../extensions/anthropic-sub-prompt.ts");
const preamble = "You help users with software engineering tasks by reading files, running commands, and editing code.";

export default function (pi: sdk.ExtensionAPI) {
 pi.registerCommand("test-anthropic-subagents", {
  description: "Check native child subscription extension loading without provider requests.",
  handler: async (_args, ctx) => {
   try {
   const agents = discoverAgents(ctx.cwd, "both").agents.filter(agent => !agent.runner);
   assert.ok(agents.length > 0);
   for (const agent of agents) {
    assert.ok(agent.subagentOnlyExtensions?.includes(extensionPath), `${agent.name} receives subscription extension`);
   }
   const agent = agents.find(agent => agent.name === "delegate")!;
   for (const mode of ["foreground", "background", "allowlist"] as const) {
    const plan = resolvePiLaunchToolPlan({
     agentName: agent.name, tools: ["read"], subagentOnlyExtensions: agent.subagentOnlyExtensions,
     ...(mode === "allowlist" ? { extensions: [] } : {}),
    });
    let session: sdk.AgentSession | undefined;
    const errors: string[] = [];
    const factory = createDefaultChildSessionFactory({
     loadPiCodingAgent: async () => ({
      ...sdk,
      createAgentSession: async (options: any) => {
       const result = await sdk.createAgentSession(options);
       session = result.session;
       return result;
      },
     }) as any,
    });
    try {
     const child = await factory.create({
      cwd: ctx.cwd, storage: { kind: "memory" }, model: "anthropic/claude-opus-5-5:high",
      tools: ["read"], extensionPaths: plan.extensionArgs,
      ambientExtensions: mode === "background" && !plan.disableAmbientExtensions,
      hooks: [{ name: "pi-subagents:prompt-runtime", factory: api => {
       api.on("before_agent_start", event => ({ systemPrompt: `${CHILD_SUBAGENT_BOUNDARY_INSTRUCTIONS}\n\n${event.systemPrompt}` }));
      } }], noSkills: true, noContextFiles: true,
      ...(mode === "foreground" ? { parentProviderRegistry: ctx.modelRegistry } : {}),
      runtime: {} as any,
      onExtensionError: error => errors.push(`${error.extensionPath} ${error.event} ${String(error.error)}`),
     });
     assert.ok(session);
     assert.equal(child.modelId, "anthropic/claude-opus-5-5");
     assert.ok(session.extensionRunner.hasHandlers("before_agent_start"), "child owns subscription prompt hook");
     const options = {
      cwd: ctx.cwd, customPrompt: "ORIGINAL_PREAMBLE", selectedTools: ["read"], toolGuidelines: {},
      sections: { child_role: "CHILD_ROLE_FIXTURE. Do only the assigned task." },
     };
     const result = await session.extensionRunner.emitBeforeAgentStart("Test child prompt.", undefined, options as any);
     assert.ok(JSON.stringify(result).includes(preamble), "subscription prompt hook actually transforms child prompt");
     assert.ok(JSON.stringify(result).includes("CHILD_ROLE_FIXTURE"), "child role instructions survive trimming");
     const forced = (result as any).systemPrompt ?? (result as any).systemPromptOptions?.forceSystemPrompt ?? (result as any).forceSystemPrompt;
     assert.ok(forced?.includes(preamble), "forced wire prompt uses subscription preamble");
     assert.ok(forced?.includes(CHILD_SUBAGENT_BOUNDARY_INSTRUCTIONS), "forced wire prompt preserves child capability boundary");
     assert.ok(!forced?.includes("ORIGINAL_PREAMBLE"), "stale forced prompt is replaced");
     assert.deepEqual(errors, [], "extensions loaded without errors");
     console.log(`PASS ${mode} real child loading, model resolution, subscription prompt hook, preserved child role`);
     await child.dispose();
    } finally {
     await factory.dispose();
    }
   }
   console.log(`PASS all ${agents.length} native agents inherit the subscription extension`);
   } catch (error) {
    process.exitCode = 1;
    console.error(error);
   } finally {
    ctx.shutdown();
   }
  },
 });
}
