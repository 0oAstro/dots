#!/usr/bin/env node
// Disposable adapter/integration fixtures only; no agents or real repositories.
import assert from 'node:assert/strict';
import * as fs from 'node:fs/promises';
import path from 'node:path';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { setupWorktree } from './setup-worktree-cow.mjs';
const exec = promisify(execFile);
const agentRoot = path.resolve(import.meta.dirname, '..');
const fixture = await fs.mkdtemp(path.join(agentRoot, 'worktrees', '.cow-test-'));
const repo = path.join(fixture, 'repo');
const hook = path.join(agentRoot, 'scripts/setup-worktree-cow.mjs');
const env = { ...process.env, GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_SYSTEM: '/dev/null' };
const git = async (root, ...args) => (await exec('git', ['-C', root, ...args], { env })).stdout;
async function write(relative, contents = 'fixture\n') {
  const file = path.join(repo, relative);
  await fs.mkdir(path.dirname(file), { recursive: true });
  await fs.writeFile(file, contents);
}
async function exists(file) {
  try { await fs.lstat(file); return true; }
  catch (error) { if (error.code === 'ENOENT') return false; throw error; }
}
async function checkout(name) {
  const destination = path.join(fixture, name);
  await git(repo, 'worktree', 'add', '-q', '-b', name, destination, 'HEAD');
  return destination;
}
try {
  await fs.mkdir(repo);
  await git(repo, 'init', '-q', '-b', 'main');
  await git(repo, 'config', 'user.name', 'CoW fixture');
  await git(repo, 'config', 'user.email', 'fixture@invalid');
  await git(repo, 'config', 'core.hooksPath', '/dev/null');
  await write('.gitignore', 'node_modules/\n.next/\ntarget/\n.env\n.worktreeinclude\n');
  await write('package.json', '{}\n');
  await write('packages/a/package.json', '{}\n');
  await write('tracked.bin', Buffer.alloc(2 * 1024 * 1024, 0x61));
  await write('packages/tracked/node_modules/keep.js');
  await git(repo, 'add', '.');
  await git(repo, 'add', '-f', 'tracked.bin', 'packages/tracked/node_modules/keep.js');
  await git(repo, 'commit', '-qm', 'fixture');
  await write('node_modules/pkg/index.js', Buffer.alloc(128 * 1024, 0x62));
  await write('node_modules/pkg/cli.sh', '#!/bin/sh\nexit 0\n');
  await fs.chmod(path.join(repo, 'node_modules/pkg/cli.sh'), 0o755);
  await fs.mkdir(path.join(repo, 'node_modules/.bin'));
  await fs.symlink('../pkg/cli.sh', path.join(repo, 'node_modules/.bin/tool'));
  await write('.next/cache/cache.bin');
  await write('packages/a/node_modules/dep/index.js');
  await write('target/debug/build.bin');
  await write('.env', 'fixture-only'); // Never printed; deliberately not allowlisted.

  const unconfigured = await checkout('no-opt-in');
  await fs.symlink(path.join(repo, 'node_modules'), path.join(unconfigured, 'node_modules'));
  assert.deepEqual(await setupWorktree({ repoRoot: repo, worktreePath: unconfigured }), { syntheticPaths: [] });
  assert.equal(await exists(path.join(unconfigured, 'node_modules')), false);
  console.log('PASS no project allowlist means no copy; Pi shared link removed without touching source');

  await write('.worktreeinclude', '/node_modules/\n/.next/\n/target/\n/packages/a/node_modules/\n');
  const manual = await checkout('manual');
  await fs.symlink(path.join(repo, 'node_modules'), path.join(manual, 'node_modules'));
  const result = await setupWorktree({ repoRoot: repo, worktreePath: manual });
  assert.deepEqual(result.syntheticPaths.sort(), ['.next', 'node_modules', 'packages/a/node_modules', 'target']);
  assert.ok((await fs.lstat(path.join(manual, 'node_modules'))).isDirectory());
  assert.notEqual((await fs.stat(path.join(repo, 'node_modules/pkg/index.js'))).ino,
    (await fs.stat(path.join(manual, 'node_modules/pkg/index.js'))).ino);
  assert.equal((await fs.stat(path.join(manual, 'node_modules/pkg/cli.sh'))).mode & 0o777, 0o755);
  assert.equal(await fs.readlink(path.join(manual, 'node_modules/.bin/tool')), '../pkg/cli.sh');
  assert.equal(await exists(path.join(manual, '.env')), false);
  const { stdout: extents } = await exec('filefrag', ['-v', path.join(manual, 'node_modules/pkg/index.js')]);
  assert.match(extents, /shared/);
  await fs.writeFile(path.join(manual, 'node_modules/pkg/index.js'), 'local write\n');
  assert.equal((await fs.readFile(path.join(repo, 'node_modules/pkg/index.js'))).length, 128 * 1024);
  await assert.rejects(setupWorktree({ repoRoot: repo, worktreePath: manual }), /already exists/);
  console.log('PASS upstream Worktrunk copying, XFS shared extents, private inodes/writes, internal links, modes, no overwrite');

  await write('.worktreeinclude', '/.env\n');
  const unsafe = await checkout('unsafe');
  await assert.rejects(setupWorktree({ repoRoot: repo, worktreePath: unsafe }), /non-cache/);
  assert.equal(await exists(path.join(unsafe, '.env')), false);
  await write('.worktreeinclude', '/packages/tracked/node_modules/\n');
  // Worktrunk's directory-boundary matching does not select a partially tracked root.
  await write('packages/tracked/node_modules/untracked.js');
  assert.deepEqual(await setupWorktree({ repoRoot: repo, worktreePath: unsafe }), { syntheticPaths: [] });
  assert.equal(await exists(path.join(unsafe, 'packages/tracked/node_modules/untracked.js')), false);
  await fs.rm(path.join(repo, 'packages/tracked/node_modules/untracked.js'));
  await write('.worktreeinclude', '/node_modules/\n/.next/\n/target/\n/packages/a/node_modules/\n');
  const bad = await checkout('bad-parent');
  await fs.symlink(path.join(repo, 'node_modules'), path.join(bad, 'packages/a/node_modules'));
  await assert.rejects(setupWorktree({ repoRoot: repo, worktreePath: bad }), /symlink/);
  assert.equal(await exists(path.join(bad, 'node_modules')), false);
  await assert.rejects(setupWorktree({ repoRoot: repo, worktreePath: repo }), /separate/);
  console.log('PASS non-cache allowlist, tracked-root, unexpected symlink, same-worktree rejection before copy');

  const { createWorktrees, diffWorktrees, cleanupWorktrees } = await import(path.join(agentRoot, 'npm/node_modules/pi-subagents/src/runs/shared/worktree.js'));
  const setup = await createWorktrees(path.join(repo, 'packages/a'), `wt-fixture-${Date.now()}`, 1, {
    provider: 'native', baseDir: path.join(fixture, 'managed'),
    setupHook: { hookPath: hook, timeoutMs: 120000 }, agents: ['fixture'],
  });
  const managed = setup.worktrees[0];
  assert.equal(managed.agentCwd, path.join(managed.path, 'packages/a'));
  assert.ok((await fs.lstat(path.join(managed.path, 'node_modules'))).isDirectory());
  const diffs = diffWorktrees(setup, ['fixture'], path.join(fixture, 'diffs'));
  assert.equal(diffs[0].error, undefined);
  assert.equal(diffs[0].filesChanged, 0);
  assert.equal(cleanupWorktrees(setup).state, 'complete');
  assert.equal(await exists(managed.path), false);
  assert.equal(await exists(path.join(repo, 'node_modules/pkg/index.js')), true);
  console.log('PASS installed Pi native allocation, Worktrunk adapter, monorepo cwd, synthetic diff exclusion and cleanup');

  const cow = path.join(fixture, 'source-cow');
  await exec('git', ['-C', repo, 'cow-worktree', 'add', '-b', 'source-cow', cow, 'HEAD'], { env });
  assert.equal(await git(cow, 'status', '--porcelain'), '');
  const { stdout: cowExtents } = await exec('filefrag', ['-v', path.join(cow, 'tracked.bin')]);
  assert.match(cowExtents, /shared/);
  await fs.writeFile(path.join(cow, 'tracked.bin'), 'independent source write\n');
  assert.equal((await fs.readFile(path.join(repo, 'tracked.bin'))).length, 2 * 1024 * 1024);
  assert.ok((await setupWorktree({ repoRoot: repo, worktreePath: cow })).syntheticPaths.includes('node_modules'));
  console.log('PASS unchanged git-cow-worktree source CoW plus optional Worktrunk caches');
} finally {
  await fs.rm(fixture, { recursive: true, force: true });
}
