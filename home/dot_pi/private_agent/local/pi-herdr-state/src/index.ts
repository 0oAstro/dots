// User-owned replacement for Herdr's Pi v9 integration.
// The managed extension must be excluded in settings to avoid competing reports.
// @ts-nocheck

import net from "node:net";
import path from "node:path";

const HERDR_ENV = process.env.HERDR_ENV;
const socketPath = process.env.HERDR_SOCKET_PATH;
const socketEndpoint =
  process.platform === "win32" && socketPath ? `\\\\.\\pipe\\${socketPath}` : socketPath;
const paneId = process.env.HERDR_PANE_ID;
const source = "herdr:pi";

function enabled() {
  return HERDR_ENV === "1" && !!socketPath && !!paneId;
}

function sendRequestAttempt(request: unknown, timeoutMs: number): Promise<boolean> {
  if (!enabled()) {
    return Promise.resolve(true);
  }

  return new Promise((resolve) => {
    let done = false;
    let timeout: ReturnType<typeof setTimeout> | undefined;
    const finish = (delivered: boolean) => {
      if (done) return;
      done = true;
      if (timeout) {
        clearTimeout(timeout);
      }
      socket.destroy();
      resolve(delivered);
    };

    const socket = net.createConnection(socketEndpoint!);
    socket.on("error", () => finish(false));
    socket.on("connect", () => socket.write(`${JSON.stringify(request)}\n`));
    socket.on("data", () => finish(true));
    socket.on("end", () => finish(false));
    timeout = setTimeout(() => finish(false), timeoutMs);
    timeout.unref?.();
  });
}

async function sendRequest(request: unknown): Promise<void> {
  if (await sendRequestAttempt(request, 500)) {
    return;
  }
  await sendRequestAttempt(request, 1500);
}

type AgentState = "working" | "blocked" | "idle" | "unknown";

type QueuedState = {
  state: AgentState;
  message?: string;
  seq: number;
};

let reportSeq = Date.now() * 1000;
let currentAgentSessionId: string | undefined;
let currentAgentSessionPath: string | undefined;

function nextReportSeq(): number {
  reportSeq += 1;
  return reportSeq;
}

function updateSessionRef(ctx: any): void {
  try {
    const file = ctx?.sessionManager?.getSessionFile?.();
    currentAgentSessionPath =
      typeof file === "string" &&
      (path.posix.isAbsolute(file) || path.win32.isAbsolute(file))
        ? file
        : undefined;
  } catch {
    currentAgentSessionPath = undefined;
  }

  try {
    const id = ctx?.sessionManager?.getSessionId?.();
    currentAgentSessionId = typeof id === "string" && id.length > 0 ? id : undefined;
  } catch {
    currentAgentSessionId = undefined;
  }
}

function withSessionRef(params: Record<string, unknown>): Record<string, unknown> {
  if (currentAgentSessionPath) {
    return { ...params, agent_session_path: currentAgentSessionPath };
  }
  if (currentAgentSessionId) {
    return { ...params, agent_session_id: currentAgentSessionId };
  }
  return params;
}

function currentSessionRef(): Record<string, unknown> | undefined {
  if (currentAgentSessionPath) {
    return { agent_session_path: currentAgentSessionPath };
  }
  if (currentAgentSessionId) {
    return { agent_session_id: currentAgentSessionId };
  }
  return undefined;
}

function reportSession(sessionStartSource?: string): Promise<void> {
  const sessionRef = currentSessionRef();
  if (!sessionRef) {
    return Promise.resolve();
  }

  return sendRequest({
    id: `${source}:session:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.report_agent_session",
    params: {
      pane_id: paneId,
      source,
      agent: "pi",
      seq: nextReportSeq(),
      session_start_source: sessionStartSource,
      ...sessionRef,
    },
  });
}

function sendState(state: AgentState, message?: string, seq = nextReportSeq()): Promise<void> {
  return sendRequest({
    id: `${source}:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.report_agent",
    params: withSessionRef({
      pane_id: paneId,
      source,
      agent: "pi",
      state,
      message,
      seq,
    }),
  });
}

let sendInFlight = false;
let queuedState: QueuedState | undefined;

function queueState(state: AgentState, message?: string): void {
  queuedState = { state, message, seq: nextReportSeq() };
  if (!sendInFlight) {
    void drainStateQueue();
  }
}

async function drainStateQueue(): Promise<void> {
  if (sendInFlight) {
    return;
  }

  sendInFlight = true;
  try {
    while (queuedState) {
      const next = queuedState;
      queuedState = undefined;
      await sendState(next.state, next.message, next.seq);
    }
  } finally {
    sendInFlight = false;
    if (queuedState) {
      void drainStateQueue();
    }
  }
}

export default function (pi) {
  if (!enabled()) {
    return;
  }

  let agentActive = false;
  let hasObservedWork = false;
  let blockedCount = 0;
  let blockedMessage: string | undefined;
  let lastState: AgentState | undefined;
  let lastMessage: string | undefined;
  let rootSession = false;
  let busyCount = 0;
  const activeRuns = new Set<string>();
  const unsubscribe: Array<() => void> = [];
  let disposeStatusRequest: (() => void) | undefined;
  let activityRevision = 0;

  function runId(data: any): string | undefined {
    const id = data?.runId ?? data?.id;
    return typeof id === "string" && id.length > 0 ? id : undefined;
  }

  function restoreActivity() {
    if (!rootSession) return;
    disposeStatusRequest?.();
    const requestId = `${source}:activity:${Date.now()}:${Math.random().toString(36).slice(2)}`;
    const revision = activityRevision;
    let timeout: ReturnType<typeof setTimeout> | undefined;
    const off = pi.events.on(`subagents:rpc:v1:reply:${requestId}`, (reply: any) => {
      dispose();
      // A completion/start may have overtaken this snapshot. Never resurrect it.
      if (!rootSession || revision !== activityRevision || reply?.success !== true) return;
      const runs = reply.data?.asyncSnapshot?.runs;
      if (!Array.isArray(runs)) return;
      activeRuns.clear();
      for (const run of runs) {
        const id = runId(run);
        if (id && (run.state === "queued" || run.state === "running")) activeRuns.add(id);
      }
      publishState();
    });
    function dispose() {
      off();
      if (timeout) clearTimeout(timeout);
      if (disposeStatusRequest === dispose) disposeStatusRequest = undefined;
    }
    disposeStatusRequest = dispose;
    timeout = setTimeout(dispose, 2000);
    timeout.unref?.();
    // Public, read-only, current-session RPC. No private registry or disk polling.
    pi.events.emit("subagents:rpc:v1:request", {
      version: 1, requestId, method: "status", params: {},
    });
  }

  function desiredState() {
    if (blockedCount > 0) {
      return { state: "blocked" as const, message: blockedMessage };
    }
    if (agentActive || busyCount > 0 || activeRuns.size > 0) {
      return { state: "working" as const, message: undefined };
    }
    // Herdr projects unseen idle reports as Done, including on a fresh launch.
    // Unknown retains lifecycle authority and displays as neutral idle without
    // inventing a completion. Only observed work may earn a later idle report.
    return { state: hasObservedWork ? "idle" as const : "unknown" as const, message: undefined };
  }

  function publishState(force = false) {
    const next = desiredState();
    if (agentActive || busyCount > 0 || activeRuns.size > 0) hasObservedWork = true;
    if (!force && next.state === lastState && next.message === lastMessage) {
      return;
    }
    lastState = next.state;
    lastMessage = next.message;
    queueState(next.state, next.message);
  }

  function onBlocked(data: any) {
    if (!rootSession) {
      return;
    }
    if (!data?.active) {
      blockedCount = Math.max(0, blockedCount - 1);
      if (blockedCount === 0) {
        blockedMessage = undefined;
      }
      publishState();
      return;
    }

    blockedCount += 1;
    blockedMessage = data.label;
    publishState();
  }

  pi.on("session_start", async (event, ctx) => {
    // TUI only: RPC/JSON/print modes are headless (no PTY herdr can display),
    // and RPC still reports hasUI=true, so mode is the reliable gate.
    if (ctx?.mode !== "tui") {
      return;
    }
    // A reload can replace this extension mid-run without another agent_start.
    agentActive = ctx?.isIdle?.() === false;
    rootSession = true;
    if (unsubscribe.length === 0) {
      unsubscribe.push(pi.events.on("herdr:blocked", onBlocked));
      unsubscribe.push(pi.events.on("herdr:busy", (data: any) => {
        activityRevision += 1;
        busyCount = data?.active ? busyCount + 1 : Math.max(0, busyCount - 1);
        publishState();
      }));
      unsubscribe.push(pi.events.on("subagent:async-started", (data: any) => {
        const id = runId(data);
        if (!id) return;
        activityRevision += 1;
        activeRuns.add(id);
        publishState();
      }));
      unsubscribe.push(pi.events.on("subagent:async-complete", (data: any) => {
        const id = runId(data);
        if (!id) return;
        activityRevision += 1;
        activeRuns.delete(id);
        publishState();
      }));
      unsubscribe.push(pi.events.on("subagents:rpc:v1:ready", restoreActivity));
    }
    updateSessionRef(ctx);
    await reportSession(event?.reason);
    if (rootSession) {
      publishState(true);
      restoreActivity();
    }
  });

  pi.on("agent_start", (_event, ctx) => {
    if (!rootSession) {
      return;
    }
    updateSessionRef(ctx);
    void reportSession();
    agentActive = true;
    publishState();
  });

  pi.on("agent_settled", (_event, ctx) => {
    if (!rootSession || ctx?.isIdle?.() !== true) {
      return;
    }

    agentActive = false;
    publishState();
  });

  pi.on("session_shutdown", () => {
    rootSession = false;
    activityRevision += 1;
    disposeStatusRequest?.();
    for (const off of unsubscribe.splice(0)) off();
    activeRuns.clear();
    busyCount = 0;
    agentActive = false;
    hasObservedWork = false;
    blockedCount = 0;
    blockedMessage = undefined;
    lastState = undefined;
    lastMessage = undefined;
  });
}
