# zdots

> Zero-lag zsh config — instant prompt, deferred loading, sub-2ms command latency.

## Benchmarks

Measured with [zsh-bench](https://github.com/romkatv/zsh-bench) (32 iterations, Apple M4 Pro):

| Metric | Score | Notes |
|---|---|---|
| `command_lag_ms` | **2.2 ms** | Per-command latency after shell ready |
| `input_lag_ms` | **6.5 ms** | Keystroke-to-screen latency |
| `first_prompt_lag_ms` | **20.7 ms** | Time to first prompt (p10k instant prompt) |
| `first_command_lag_ms` | **129 ms** | Time to first command output |
| `exit_time_ms` | **49 ms** | `zsh -lic exit` wall time |

**`command_lag` is 21× faster** than the unoptimized config (47 ms → 2.2 ms).

Raw `hyperfine`:

```
Benchmark 1: zsh -i -c exit
  Time (mean ± σ):      43.3 ms ± 1.7 ms
  Range (min … max):    41.5 ms … 46.9 ms
```

## Philosophy

- **Zero-fork `.zshenv`.** No `date`, `mkdir`, `chmod`, `uname`, `id` — only zsh builtins and static exports. Every fork costs ~1 ms; this file is sourced for *all* shells including scripts.
- **Instant prompt, deferred everything else.** p10k instant prompt renders in ~0 ms. Heavy plugins (FSH, autosuggestions) load synchronously but p10k's cached prompt hides the wait. Non-essential init (autopair, forgit, brew, cargo, zoxide, clipboard, history-aux) is deferred to the first precmd hook — runs before you can type.
- **`ZSH_AUTOSUGGEST_MANUAL_REBIND=1`.** The single biggest perf win. Prevents autosuggestions from rebinding all ZLE widgets on every precmd. Cuts command_lag from ~47 ms to ~2 ms.
- **p10k SSH detection bypass.** Pre-set `P9K_SSH` / `_P9K_SSH_TTY` before p10k loads, eliminating the `who -m` fork (~8 ms saved).
- **Modular + compiled.** 9 files in `config/` — each compiled to `.zwc` bytecode via `zcompile`. zsh auto-recompiles when source is newer than `.zwc`, so editing `config/*.zsh` and restarting just works. Run `recompile` to force regeneration. ⚠️ If reverting with `mv`, run `touch` on the restored file afterward — `mv` preserves mtime and zsh will trust the stale `.zwc`.
- **Lazy-loaded tools.** `brew`, `cargo`/`rustc`/`rustup`, `z`/`zoxide`/`zi` are placeholder functions that init on first call. Zero cost until you need them.

## Setup

```zsh
# 1. Clone
export ZDOTDIR=~/.config/zsh
git clone git@github.com:0oAstro/zdots.git $ZDOTDIR

# 2. Bootstrap .zshenv (so zsh finds ZDOTDIR)
cat << 'EOF' >| ~/.zshenv
export ZDOTDIR=~/.config/zsh
[[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv
EOF

# 3. Reload
exec zsh
```

## Structure

```
~/.config/zsh/
├── .zshrc              # interactive shell entry point (20 lines)
├── .zshenv             # always-sourced env — zero forks
├── .zprofile           # login shell — mkdir/chmod (rare, one-time)
├── .zsh_plugins.txt    # antidote plugin manifest
├── .zsh_plugins.zsh    # generated static plugin loader
├── .p10k.zsh           # powerlevel10k config (Pure style)
├── .zstyles            # zstyle settings
├── config/             # modular config (zwc-compiled, auto-reload on edit)
│   ├── 00-opts.zsh         # shell options, history, key bindings, fpath, fzf
│   ├── 01-plugins.zsh      # antidote static plugin source
│   ├── 02-theme.zsh        # Rosé Pine FSH theme
│   ├── 03-completions.zsh  # completion zstyles
│   ├── 04-env.zsh          # environment, secrets, FZF, XDG, PATH, Bitwarden
│   ├── 05-aliases.zsh      # all aliases
│   ├── 06-funcs.zsh        # helper functions (bak, touchf, up, ls→eza)
│   ├── 07-deferred.zsh     # deferred precmd hook (lazy tools, widgets)
│   └── 08-prompt.zsh       # directory backrefs, p10k finalize
├── functions/          # custom autoloaded functions (trash, cdf, extract …)
├── lib/rose-pine/      # Rosé Pine theme for FSH
└── .antidote/          # plugin cache (gitignored)
```

## Init order

| Phase | What | Cost |
|---|---|---|
| **`.zshenv`** | ZDOTDIR, XDG dirs, Homebrew env (static), PATH (static) | ~3 ms |
| **Instant prompt** | p10k cached prompt renders immediately | ~0 ms |
| **Pokeget** | Random pokémon greeting | ~2 ms |
| **config/00-opts** | Shell options, history, key bindings, fpath, fzf widgets | ~1 ms |
| **config/01-plugins** | ez-compinit (lazy), p10k, FSH, autosuggestions, history-substring-search | ~15 ms |
| **config/02-theme** | Rosé Pine FSH theme | ~1 ms |
| **config/03-completions** | Completion zstyles + .zstyles source | ~1 ms |
| **config/04-env** | Environment, secrets, FZF, XDG, PATH, Bitwarden, SPA | ~1 ms |
| **config/05-aliases** | All aliases + conditional python/dir helpers | ~1 ms |
| **config/06-funcs** | Helper functions (bak, touchf, up, ls→eza) | ~1 ms |
| **config/08-prompt** | Directory backrefs, p10k finalize | ~1 ms |
| **Deferred precmd** | config/07-deferred: autopair, forgit, brew/cargo/zoxide lazy stubs, clipboard, fancy-ctrl-z, magic-enter, globalias, history-aux, key bindings | ~10 ms |

## Plugins

| Plugin | Load | Why |
|---|---|---|
| [powerlevel10k](https://github.com/romkatv/powerlevel10k) | Sync | Prompt — instant prompt + async git status |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Sync | Syntax highlighting (needs first keystroke) |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Sync | Fish-style suggestions (needs first keystroke) |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Sync | Up/Down searches history |
| [ez-compinit](https://github.com/mattmc3/ez-compinit) | Sync | Lazy compinit on first precmd |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | fpath only | Extra tab-completions |
| [zsh-autopair](https://github.com/hlissner/zsh-autopair) | Deferred | Bracket/quote auto-close |
| [zsh-no-ps2](https://github.com/romkatv/zsh-no-ps2) | Sync | No `>` continuation prompt |
| [forgit](https://github.com/wfxr/forgit) | Deferred | Interactive git with fzf |
| [git-cmds](https://github.com/mattmc3/git-cmds) | PATH | Extra git subcommands |

## Lazy-loaded tools

These tools are zero-cost at startup — placeholder functions init on first call:

| Tool | Placeholder commands | Init on first call |
|---|---|---|
| Homebrew | `brew` | `brew shellenv` |
| Cargo/Rust | `cargo`, `rustc`, `rustup` | `source $CARGO_HOME/env` |
| Zoxide | `z`, `zoxide`, `zi` | `zoxide init zsh` |

## Performance tricks

### zwc bytecode (safe usage)

Every `config/*.zsh` file is compiled to `.zwc` via `zcompile`. zsh auto-recompiles when the source is newer than the bytecode, so normal editing works transparently.

**The one footgun:** `mv` preserves file modification time.

```zsh
# ❌ BROKEN: revert with mv — stale .zwc wins
cp config/00-opts.zsh config/00-opts.bak
vi config/00-opts.zsh        # edit → zsh auto-recompiles
exec zsh                      # oops, that broke things
mv config/00-opts.bak config/00-opts.zsh  # mv preserves old mtime
exec zsh                      # ❌ loads stale bytecode!

# ✅ FIX: touch after mv
mv config/00-opts.bak config/00-opts.zsh
touch config/00-opts.zsh      # update mtime → zsh recompiles
exec zsh                      # ✅ loads fresh source
```

Or just use `cp` instead of `mv` to revert — `cp` updates mtime.

Run `recompile` anytime to force-regenerate all `.zwc` files.

### `ZSH_AUTOSUGGEST_MANUAL_REBIND=1`

Without this, autosuggestions rebinds every ZLE widget on **every precmd** — that's hundreds of `zle -N` calls per command. Setting this flag disables automatic rebinding, saving ~45 ms per command cycle. You must manually call `_zsh_autosuggest_bind_widgets` if you add new widgets after startup.

### p10k SSH bypass

p10k calls `who -m` (~8 ms fork) to detect SSH sessions. We pre-set `P9K_SSH=0` and `_P9K_SSH_TTY=$TTY` before p10k loads, so `_p9k_init_ssh` returns immediately. In actual SSH sessions, `SSH_CLIENT`/`SSH_TTY`/`SSH_CONNECTION` are set by sshd, so our pre-set `P9K_SSH=1` is correct.

### Zero-fork `.zshenv`

Every external command (`date`, `mkdir`, `id`, `uname`, `test -x`) costs ~1 ms. Since `.zshenv` is sourced for **all** zsh invocations (including scripts), we eliminated every fork:

| Before | After | Saved |
|---|---|---|
| `$(id -u)` | `$UID` (builtin) | ~1 ms |
| `uname -s` | `$OSTYPE` (builtin) | ~1 ms |
| `[[ -x /opt/homebrew/bin/brew ]]` | Static exports | ~1 ms |
| `mkdir -p $XDG_RUNTIME_DIR` | Moved to `.zprofile` | ~0.5 ms |
| `chmod 700 $XDG_RUNTIME_DIR` | Moved to `.zprofile` | ~0.6 ms |
| `date -r` cache checks | Eliminated entirely | ~3 ms |

### Deferred precmd hook

Non-essential setup runs in a precmd hook that fires **once**, after the prompt appears. The user never sees a delay — they can't type fast enough to beat it.

Deferred items: autopair-init, forgit, brew/cargo/zoxide lazy stubs, clipboard helpers, fancy-ctrl-z, magic-enter, globalias, pokeget Ctrl+L, history-aux (sqlite + json), fzf widget bindings, key bindings.

## Secrets

API keys and tokens live in the macOS Keychain, cached to `$XDG_CACHE_HOME/zsh/secrets-cache.zsh` on first shell load. Zero forks on subsequent loads — just a `source` of the cached file.

## Dependencies

| Tool | Purpose | Install |
|---|---|---|
| zsh ≥ 5.8 | Shell | ships with macOS |
| antidote | Plugin manager | bootstrapped by `.zshrc` |
| powerlevel10k | Prompt | antidote plugin |
| fzf | Fuzzy finder | `brew install fzf` |
| zoxide | Smarter cd | `brew install zoxide` |
| eza | `ls` replacement | `brew install eza` |
| fd | Fast `find` | `brew install fd` |
| bat | `cat` replacement | `brew install bat` |
| pokeget | Greeting pokémon | `brew install pokeget` |
| bwbio | Bitwarden Touch ID | `brew install bwbio` |
| bitwarden-cli | Secrets backend | `brew install bitwarden-cli` |
| sqlite3 | History DB | ships with macOS |
| jq | History JSON | `brew install jq` |
| trash | `rm` replacement | `brew install trash` |
