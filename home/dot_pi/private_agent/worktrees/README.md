# Pi CoW worktrees

## Installed tools and configuration

- Worktrunk **v0.80.0** is installed by mise (`aqua:max-sixty/worktrunk@0.80.0`).
  `~/.local/bin/wt` points to that pinned installation. No shell integration,
  project hooks, or auto-update service were enabled.
- `git-cow-worktree` remains installed unchanged at `~/.local/bin/git-cow-worktree`,
  version `v0.0.0-20260817193435-0f6852cebe49`, commit
  `0f6852cebe494a29dd5fe28eb5077bdb8fda912c`.
- `~/.pi/agent/extensions/subagent/config.json` still selects native allocation,
  puts managed worktrees here, preserves the 600000 ms agent timeout, and invokes
  `~/.pi/agent/scripts/setup-worktree-cow.mjs` with a 120000 ms setup timeout.
- The setup script is now only a **Pi JSON/Worktrunk adapter**, not a copier.
  Worktrunk owns directory traversal, file copying, reflinks, and symlink copying.
  The previous bespoke copier has been replaced, not retained as a fallback.
- Managed isolation remains opt-in (`worktree: true`). `/opt/docker` itself is not
  a Git repository. No global default requiring Git was added.

This directory is XFS with `reflink=1`. `/tmp` is tmpfs; do not put CoW worktrees
there. Git worktree isolation is not an OS/security sandbox.

## Explicit project cache opt-in

**No `.worktreeinclude` in the source checkout means no cache copying.** No
allowlists were added to existing repositories automatically.

To opt in, first review the contents of the proposed cache trees and symlinks,
then add `.worktreeinclude` at that repository's root. For example:

```gitignore
# Only add paths whose contents have been reviewed as disposable/non-sensitive.
/node_modules/
/target/
/packages/frontend/node_modules/
```

Worktrunk matches gitignore-style patterns against Git-discovered **ignored
entries**. The directory must be Git-ignored in the source and destination.
Tracked files are not selected by Worktrunk. The adapter additionally rejects
selected directories containing tracked paths in either worktree.

The Pi adapter accepts only directory roots named `node_modules`, `target`,
`.next`, or `.next/cache` (including monorepo paths). It rejects direct environment
files, uploads, databases, broad `.cache` trees, virtualenvs, and other non-cache
selections before copying. A broad pattern selecting other ignored entries fails
setup rather than quietly copying them.

**Important Worktrunk limitations, explicitly accepted for this setup:**

- Filters apply to top-level ignored entries, not recursively within a selected
  directory. Selecting `node_modules/` copies its entire contents, including any
  nested `.env`, credential file, or other sensitive data. Do not opt in a cache
  tree that contains such data; a nested exclude is not a security filter.
- Symlinks are copied as-is, never followed by the copier. Relative internal
  dependency links work, but absolute/external links may still point to the source
  checkout or shared stores. Review links; do not assume all dependency writes
  are isolated if such links exist.
- If Git reports `.next/` as one ignored directory, `.next/cache/` alone will not
  select it. Opt in `/.next/` only after reviewing the **whole** directory, or leave
  it out. We deliberately do not generate include rules or alter Git ignores.

pi-subagents 0.73.1 creates a shared root `node_modules` symlink before setup.
The adapter removes only that exact automatic link, never its source target,
even when no allowlist exists. An unexpected/ tracked destination link fails
setup. It checks selected cache roots/ancestors for symlinks, but does not walk
or rewrite links inside cache trees.

## Copy lifecycle

The adapter runs Worktrunk's machine-readable dry run, validates the selected
cache roots, then runs:

```sh
wt -C DESTINATION step copy-ignored --from SOURCE_BRANCH --require-include --format json
```

The source checkout must be on a named branch, because Worktrunk's `--from`
selects worktrees by branch. A detached source with an allowlist fails before
copying. The source and destination must be separate worktrees belonging to the
same repository on the same filesystem.

Setup is **create-only**: selected destination cache directories must not exist.
No `--force` is used. To refresh caches, use the package manager/build tool inside
that worktree; do not rerun this Pi setup adapter over existing caches.

Worktrunk reflinks on XFS. It can fall back to full file copies on unsupported
filesystems; the adapter checks the JSON `written` count and fails launch if
any full copies occurred. Partial copy/setup failure is handled by Pi's existing
managed setup rollback; for manual worktrees, stop and inspect partial caches
before retrying. The adapter does not implement a second copy/cleanup engine.

Freeze source caches, source branch, and allowlist during setup. Directory copies
are not atomic snapshots. Build artifacts may require rebuilding after ref or
toolchain changes. Managed Pi `syntheticPaths` removes copied cache roots before
diff capture so helper files do not pollute patches. Manual worktrees keep their
ignored caches until normal worktree cleanup.

## Usage

Managed Pi child: pass `worktree: true` on an authorized delegation; native Pi
allocation invokes the adapter automatically. No additional Worktrunk hooks are
needed. Read-only/shared-cwd/non-Git runs can use `worktree: false`.

Manual source-CoW checkout (experimental upstream helper):

```sh
# From a Git repository; choose a new branch and nonexistent destination.
project=$(basename "$(git rev-parse --show-toplevel)")
mkdir -p "$HOME/.pi/agent/worktrees/$project"
git cow-worktree add -v -b agent/task \
  "$HOME/.pi/agent/worktrees/$project/manual-task" HEAD
cd "$HOME/.pi/agent/worktrees/$project/manual-task"
pi
```

This shares tracked source blocks, unlike native Pi source checkout. The helper
can fall back to ordinary Git checkout when reflinks are unavailable. It supports
only `add`; use normal Git for listing/removing/pruning worktrees.

`/skill:cow-worktrees` documents optional manual Worktrunk cache setup. Never
launch Docker stacks from these checkouts without separate explicit deployment
authorization. No real repository or Docker stack was modified during setup.

## Validation and maintenance

```sh
wt --version
node ~/.pi/agent/scripts/test-worktree-cow.mjs
go version -m ~/.local/bin/git-cow-worktree
```

Tests use disposable local repositories only. They verify no-copy without opt-in,
non-cache selection rejection, tracked-root protection, symlink-root checks,
private inodes/shared XFS extents/independent writes, actual installed Pi native
allocation/adapter/diff/cleanup, and unchanged manual `git-cow-worktree` operation.
They do not claim recursive secret filtering or external-symlink isolation.
Fixtures are removed in `finally`; no agents or services are launched.

Run `/reload` or restart Pi after changing config/skill resources. Re-run tests
after upgrading Worktrunk or pi-subagents. To upgrade Worktrunk deliberately,
install a reviewed version with mise, then repoint `~/.local/bin/wt`; no automatic
upgrades were configured. The pinned source-CoW helper is independently managed.

Disabling `worktreeSetupHook` and `worktreeSetupHookTimeoutMs` restores the
installed subagent package's default shared root `node_modules` link behavior.
There is no timer sweeping this directory. Preserve worktrees until handoff is
durable and no process owns them; use normal `git worktree remove` after review,
without force for dirty worktrees. Branch deletion requires separate authority.

These home-directory Pi files/worktrees are outside the Docker backup policy.
CoW sharing is not a backup. Push or otherwise durably hand off source changes;
caches are disposable. No backup, snapshot, mount, or backup service was started.
