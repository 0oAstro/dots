import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';
import path from 'node:path';
import { registerHerdrStatusBridge } from '../../../npm/node_modules/pi-subagents/src/integrations/herdr-status.js';
import { buildAsyncStatusSnapshot } from '../../../npm/node_modules/pi-subagents/src/runs/background/async-status-snapshot.js';

const source = stripTypeScriptTypes(readFileSync(new URL('../src/index.ts', import.meta.url), 'utf8'))
  .replace('import net from "node:net";', '')
  .replace('import path from "node:path";', '')
  .replace('export default function (pi)', 'globalThis.install = function (pi)');

function harness({ enabled = true, mode = 'tui', idle = true, snapshot = [], autoStatus = true } = {}) {
  const reports = [];
  const requests = [];
  const hooks = new Map();
  const bus = new EventEmitter();
  const timers = new Set();
  let mainIdle = idle;
  const env = { HERDR_ENV: enabled ? '1' : '0', HERDR_SOCKET_PATH: '/test/herdr.sock', HERDR_PANE_ID: 'w1:p1' };
  const sandbox = {
    net: {
      createConnection() {
        const socket = new EventEmitter();
        socket.destroy = () => {};
        socket.write = (line) => {
          reports.push(JSON.parse(line));
          queueMicrotask(() => socket.emit('data', Buffer.from('{}\n')));
        };
        queueMicrotask(() => socket.emit('connect'));
        return socket;
      },
    },
    path,
    process: { env, platform: 'linux' },
    setTimeout: (callback, delay) => {
      const timer = { callback, delay, unref() {} };
      timers.add(timer);
      return timer;
    },
    clearTimeout: (timer) => timers.delete(timer),
    setInterval() { assert.fail('reporter must not poll a private registry'); },
  };
  const events = {
    on(event, handler) { bus.on(event, handler); return () => bus.off(event, handler); },
    emit(event, data) { bus.emit(event, data); },
  };
  // Mock the public RPC only, never the removed manager registry.
  if (autoStatus) events.on('subagents:rpc:v1:request', (request) => {
    requests.push(request);
    queueMicrotask(() => events.emit(`subagents:rpc:v1:reply:${request.requestId}`, {
      version: 1, success: true, data: { asyncSnapshot: { runs: snapshot } },
    }));
  });
  else events.on('subagents:rpc:v1:request', (request) => requests.push(request));
  vm.createContext(sandbox);
  vm.runInContext(source, sandbox);
  sandbox.install({ on(event, handler) { hooks.set(event, handler); }, events });
  const ctx = {
    mode,
    hasUI: mode === 'tui' || mode === 'rpc',
    isIdle: () => mainIdle,
    sessionManager: { getSessionFile: () => '/test/root.jsonl', getSessionId: () => 'root-session' },
  };
  const flush = () => new Promise((resolve) => setImmediate(resolve));
  const event = async (name, data = {}) => { await hooks.get(name)?.(data, ctx); await flush(); };
  const emit = async (name, data = {}) => { events.emit(name, data); await flush(); };
  return {
    reports, requests, hooks, bus, events, env, timers, event, emit, flush,
    setIdle(value) { mainIdle = value; },
    states() { return reports.filter((report) => report.method === 'pane.report_agent').map((report) => report.params.state); },
    async reply(data, success = true) {
      const request = requests.at(-1);
      await emit(`subagents:rpc:v1:reply:${request.requestId}`, { version: 1, success, data });
    },
    async expireRequests() {
      for (const timer of [...timers]) if (timer.delay === 2000) { timers.delete(timer); timer.callback(); }
      await flush();
    },
  };
}

const start = (h, id) => h.emit('subagent:async-started', { id });
const complete = (h, id, status = 'completed') => h.emit('subagent:async-complete', { runId: id, status });

test('fresh open session claims neutral authority without reporting completion', async () => {
  const h = harness();
  await h.event('session_start', { reason: 'startup' });
  assert.deepEqual(h.states(), ['unknown']);
  assert.equal(h.reports[0].method, 'pane.report_agent_session');
  assert.equal(h.reports[0].params.session_start_source, 'startup');
  assert.equal(h.reports.at(-1).params.agent_session_path, '/test/root.jsonl');
  await h.event('agent_settled');
  await h.emit('subagents:rpc:v1:ready');
  assert.deepEqual(h.states(), ['unknown']);
});

test('idle startup/reload/resume/new sessions do not invent a completed turn', async () => {
  for (const reason of ['startup', 'reload', 'resume', 'new']) {
    const h = harness();
    await h.event('session_start', { reason });
    await h.emit('herdr:busy', { active: false });
    await complete(h, 'unobserved');
    await h.event('agent_settled');
    assert.deepEqual(h.states(), ['unknown'], reason);
  }
});

test('first main turn earns completion only after settling', async () => {
  const h = harness();
  await h.event('session_start');
  h.setIdle(false);
  await h.event('agent_start');
  await h.event('agent_settled');
  assert.deepEqual(h.states(), ['unknown', 'working']);
  h.setIdle(true);
  await h.event('agent_settled');
  assert.deepEqual(h.states(), ['unknown', 'working', 'idle']);
});

test('blocking before any work clears to neutral instead of complete', async () => {
  const h = harness();
  await h.event('session_start');
  await h.emit('herdr:blocked', { active: true, label: 'Startup question' });
  await h.emit('herdr:blocked', { active: false });
  assert.deepEqual(h.states(), ['unknown', 'blocked', 'unknown']);
});

test('work observed under a blocker still earns completion', async () => {
  const h = harness();
  await h.event('session_start');
  await h.emit('herdr:blocked', { active: true });
  await start(h, 'child');
  await complete(h, 'child');
  assert.equal(h.states().at(-1), 'blocked');
  await h.emit('herdr:blocked', { active: false });
  assert.deepEqual(h.states(), ['unknown', 'blocked', 'idle']);
});

test('empty restoration after completed work does not erase earned completion', async () => {
  const h = harness();
  await h.event('session_start');
  await start(h, 'child');
  await complete(h, 'child');
  await h.emit('subagents:rpc:v1:ready');
  assert.deepEqual(h.states(), ['unknown', 'working', 'idle']);
});

test('new session after shutdown does not inherit previous completion', async () => {
  const h = harness();
  await h.event('session_start');
  await h.event('agent_start');
  await h.event('agent_settled');
  assert.equal(h.states().at(-1), 'idle');
  await h.event('session_shutdown');
  await h.event('session_start', { reason: 'new' });
  assert.equal(h.states().at(-1), 'unknown');
});

test('main settling stays working until its background workflow completes', async () => {
  const h = harness();
  await h.event('session_start');
  h.setIdle(false);
  await h.event('agent_start');
  await start(h, 'workflow');
  h.setIdle(true);
  await h.event('agent_settled');
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'workflow');
  assert.equal(h.states().at(-1), 'idle');
  for (const report of h.reports) {
    assert.equal(report.params.source, 'herdr:pi');
    assert.equal(report.params.agent_session_path, '/test/root.jsonl');
  }
  const seqs = h.reports.map((report) => report.params.seq);
  assert.ok(seqs.every((seq, i) => i === 0 || seq > seqs[i - 1]));
});

test('counted herdr:busy keeps a settled parent working without a registry', async () => {
  const h = harness();
  await h.event('session_start');
  await h.emit('herdr:busy', { active: true, label: '2 agents' });
  await h.emit('herdr:busy', { active: true, label: 'Another owner' });
  await h.event('agent_settled');
  await h.emit('herdr:busy', { active: false });
  assert.equal(h.states().at(-1), 'working');
  await h.emit('herdr:busy', { active: false });
  await h.emit('herdr:busy', { active: false });
  assert.equal(h.states().at(-1), 'idle');
});

test('concurrent success/failure/stop and duplicate starts are tracked by run id', async () => {
  const h = harness();
  await h.event('session_start');
  await start(h, 'one');
  await start(h, 'one');
  await start(h, 'two');
  await start(h, 'three');
  await complete(h, 'one');
  await complete(h, 'two', 'failed');
  await complete(h, 'unknown');
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'three', 'stopped');
  assert.deepEqual(h.states(), ['unknown', 'working', 'idle']);
});

test('completion cannot idle an active main agent', async () => {
  const h = harness({ idle: false });
  await h.event('session_start');
  await start(h, 'child');
  await complete(h, 'child');
  assert.deepEqual(h.states(), ['working']);
  h.setIdle(true);
  await h.event('agent_settled');
  assert.equal(h.states().at(-1), 'idle');
});

test('startup restores queued/running workflows from the actual public snapshot schema', async () => {
  const jobs = ['queued', 'running', 'complete', 'failed', 'paused', 'stopped'].map((status) => ({
    asyncId: status, status, mode: 'workflow', agents: ['worker'], startedAt: 1,
  }));
  const snapshot = buildAsyncStatusSnapshot(jobs);
  const h = harness({ snapshot: snapshot.runs });
  await h.event('session_start', { reason: 'reload' });
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'queued');
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'running');
  assert.equal(h.states().at(-1), 'idle');
  assert.deepEqual(h.states(), ['unknown', 'working', 'idle']);
  assert.equal(h.requests[0].method, 'status');
  assert.deepEqual(Object.keys(h.requests[0].params), []);
});

test('RPC ready restores activity when the subagent extension starts first or last', async () => {
  const h = harness({ autoStatus: false });
  await h.event('session_start');
  await h.emit('subagents:rpc:v1:ready');
  assert.equal(h.requests.length, 2);
  await h.reply({ asyncSnapshot: { runs: [{ id: 'restored', state: 'running' }] } });
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'restored');
  assert.equal(h.states().at(-1), 'idle');
  assert.equal(h.timers.size, 0);
});

test('stale snapshot cannot resurrect a completed run', async () => {
  const h = harness({ autoStatus: false });
  await h.event('session_start');
  await start(h, 'done');
  await complete(h, 'done');
  await h.reply({ asyncSnapshot: { runs: [{ id: 'done', state: 'running' }] } });
  assert.equal(h.states().at(-1), 'idle');
});

test('stale empty snapshot cannot erase newly started work', async () => {
  const h = harness({ autoStatus: false });
  await h.event('session_start');
  await start(h, 'new');
  await h.reply({ asyncSnapshot: { runs: [] } });
  assert.equal(h.states().at(-1), 'working');
});

test('missing RPC provider expires the listener without affecting main lifecycle', async () => {
  const h = harness({ autoStatus: false });
  await h.event('session_start');
  await h.expireRequests();
  assert.equal(h.timers.size, 0);
  assert.ok(!h.bus.eventNames().some((name) => name.startsWith('subagents:rpc:v1:reply:')));
  await h.event('agent_start');
  await h.event('agent_settled');
  assert.deepEqual(h.states(), ['unknown', 'working', 'idle']);
});

test('failed or malformed RPC replies preserve observed activity', async () => {
  for (const data of [{}, { asyncSnapshot: { runs: null } }]) {
    const h = harness({ autoStatus: false });
    await h.event('session_start');
    await h.reply(data);
    assert.equal(h.states().at(-1), 'unknown');
    assert.equal(h.timers.size, 0);
  }
  const h = harness({ autoStatus: false });
  await h.event('session_start');
  await h.reply({}, false);
  assert.equal(h.states().at(-1), 'unknown');
});

test('blocked priority clears back to subagent working state', async () => {
  const h = harness();
  await h.event('session_start');
  await start(h, 'child');
  await h.emit('herdr:blocked', { active: true, label: 'Approval needed' });
  await h.emit('herdr:blocked', { active: true, label: 'Second approval' });
  await h.emit('herdr:blocked', { active: false });
  assert.equal(h.states().at(-1), 'blocked');
  assert.equal(h.reports.at(-1).params.message, 'Second approval');
  await h.emit('herdr:blocked', { active: false });
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'child');
  assert.equal(h.states().at(-1), 'idle');
});

test('actual installed pi-subagents bridge keeps parent working and releases on final completion', async () => {
  const h = harness();
  const bridge = registerHerdrStatusBridge({ events: h.events, env: h.env, refreshMs: 0, runHerdr: async () => {} });
  await h.event('session_start');
  bridge.sessionStarted({ hasUI: true, runs: [] });
  await start(h, 'one');
  await start(h, 'two');
  await h.event('agent_settled');
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'one');
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'two');
  assert.equal(h.states().at(-1), 'idle');
  bridge.dispose();
  await bridge.flush();
});

test('actual bridge restores busy work even if its signal precedes reporter startup', async () => {
  const h = harness({ snapshot: [{ id: 'existing', state: 'running' }] });
  const bridge = registerHerdrStatusBridge({ events: h.events, env: h.env, refreshMs: 0, runHerdr: async () => {} });
  bridge.sessionStarted({ hasUI: true, runs: [{ id: 'existing' }] });
  await h.event('session_start');
  assert.equal(h.states().at(-1), 'working');
  await complete(h, 'existing');
  assert.equal(h.states().at(-1), 'idle');
  bridge.dispose();
  await bridge.flush();
});

for (const mode of ['rpc', 'json', 'print']) {
  test(`${mode} sessions never report or attach activity listeners`, async () => {
    const h = harness({ mode });
    await h.event('session_start');
    await h.event('agent_start');
    await start(h, 'child');
    await h.emit('herdr:busy', { active: true });
    await h.emit('herdr:blocked', { active: true });
    assert.deepEqual(h.reports, []);
    assert.equal(h.requests.length, 0);
    assert.equal(h.timers.size, 0);
    assert.equal(h.bus.listenerCount('herdr:busy'), 0);
  });
}

test('outside Herdr the replacement is inert', async () => {
  const h = harness({ enabled: false });
  assert.equal(h.hooks.size, 0);
  assert.equal(h.timers.size, 0);
  assert.equal(h.bus.listenerCount('herdr:busy'), 0);
});

test('shutdown disposes outstanding requests/listeners and late replies; rebind is clean', async () => {
  const h = harness({ autoStatus: false });
  await h.event('session_start');
  await h.event('session_start');
  assert.equal(h.bus.listenerCount('herdr:busy'), 1);
  await start(h, 'old');
  await h.event('session_shutdown');
  assert.equal(h.timers.size, 0);
  assert.deepEqual(h.bus.eventNames(), ['subagents:rpc:v1:request']);
  const count = h.reports.length;
  await h.reply({ asyncSnapshot: { runs: [{ id: 'late', state: 'running' }] } });
  await start(h, 'late');
  await h.event('agent_start');
  assert.equal(h.reports.length, count);
  await h.event('session_start');
  assert.equal(h.states().at(-1), 'unknown');
  assert.equal(h.bus.listenerCount('herdr:busy'), 1);
  await h.event('session_shutdown');
  assert.equal(h.timers.size, 0);
});
