# zdots

> Zero-lag zsh config — instant prompt, deferred loading, sub-2ms command latency.

## Benchmarks

Measured with [zsh-bench](https://github.com/romkatv/zsh-bench) (32 iterations, Apple M4 Pro):

| Metric | Score | Notes |
|---|---|---|
| `command_lag_ms` | **2.2 ms** | Per-command latency after shell ready |
| `input_lag_ms` | **6.5 ms** | Keystroke-to-screen latency |
| `first_prompt_lag_ms` | **~25 ms** | Time to first prompt (starship) |
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
- **Starship prompt.** Lightweight, pure-Rust prompt with no shell-level instant-prompt complexity. Renders quickly without the edge cases p10k had with terminal state/sizing.
- **`ZSH_AUTOSUGGEST_MANUAL_REBIND=1`.** The single biggest perf win. Prevents autosuggestions from rebinding all ZLE widgets on every precmd. Avoids a large per-command widget-rebind tax.
- **Modular + compiled.** 9 files in `config/` — each compiled to `.zwc` bytecode via `zcompile`. zsh auto-loads adjacent `.zwc` bytecode when it is newer than the source. Source `.zsh` files, never `.zwc` directly. Run `recompile` after edits to regenerate bytecode.
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
├── .zstyles            # zstyle settings
├── starship.toml       # starship prompt config (in ~/.config/starship.toml)
├── config/             # modular config (zwc-compiled, auto-reload on edit)
│   ├── 00-opts.zsh         # shell options, history, key bindings, fpath, fzf
│   ├── 01-plugins.zsh      # antidote static plugin source
│   ├── 02-theme.zsh        # Rosé Pine FSH theme
│   ├── 03-completions.zsh  # completion zstyles
│   ├── 04-env.zsh          # environment, secrets, FZF, XDG, PATH, Bitwarden
│   ├── 05-aliases.zsh      # all aliases
│   ├── 06-funcs.zsh        # helper functions (bak, touchf, up, ls→eza)
│   ├── 07-widgets.zsh      # widgets, fzf/git helpers, history aux, zsh4humans-style keys
│   ├── 08-prompt.zsh       # directory backrefs
│   └── 09-z4h-integrations.zsh # zssh, ztmux, terminfo, fzf completion UX
├── functions/          # custom autoloaded functions (trash, cdf, extract …)
├── lib/rose-pine/      # Rosé Pine theme for FSH
└── .antidote/          # plugin cache (gitignored)
```

## Init order

| Phase | What | Cost |
|---|---|---|
| **`.zshenv`** | ZDOTDIR, XDG dirs, Homebrew env (static), PATH (static) | ~3 ms |
| **Starship init** | `eval "$(starship init zsh)"` — sets precmd hook | ~2 ms |
| **Pokeget** | Random pokémon greeting | ~2 ms |
| **config/00-opts** | Shell options, history, key bindings, fpath, fzf widgets | ~1 ms |
| **config/01-plugins** | ez-compinit (lazy), FSH, autosuggestions, history-substring-search | ~15 ms |
| **config/02-theme** | Rosé Pine FSH theme | ~1 ms |
| **config/03-completions** | Completion zstyles + .zstyles source | ~1 ms |
| **config/04-env** | Environment, secrets, FZF, XDG, PATH, Bitwarden, SPA | ~1 ms |
| **config/05-aliases** | All aliases + conditional python/dir helpers | ~1 ms |
| **config/06-funcs** | Helper functions (bak, touchf, up, ls→eza) | ~1 ms |
| **config/08-prompt** | Directory backrefs | ~1 ms |
| **config/07-widgets** | forgit, zoxide lazy stubs, clipboard, fancy-ctrl-z, magic-enter, globalias, history-aux, zsh4humans-style key bindings | ~10 ms |

## Plugins

| Plugin | Load | Why |
|---|---|---|
| [starship](https://starship.rs) | Sync | Prompt — pure Rust, simple, no terminal edge-cases |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Sync | Syntax highlighting (needs first keystroke) |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Sync | Fish-style suggestions (needs first keystroke) |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Sync | Up/Down searches history |
| [ez-compinit](https://github.com/mattmc3/ez-compinit) | Sync | Lazy compinit on first precmd |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | fpath only | Extra tab-completions |
| [zsh-autopair](https://github.com/hlissner/zsh-autopair) | Deferred | Bracket/quote auto-close |
| [zsh-no-ps2](https://github.com/romkatv/zsh-no-ps2) | Sync | No `>` continuation prompt |
| [forgit](https://github.com/wfxr/forgit) | Deferred | Interactive git with fzf |
| [git-cmds](https://github.com/mattmc3/git-cmds) | PATH | Extra git subcommands |


## zsh4humans-style integrations

- `Tab` uses compsys-backed `fzf-tab`, so command-specific completions like `brew install <Tab>` stay correct.
- `Alt-C` opens an fzf directory picker and runs `cd`.
- `ztmux [session]` starts/attaches tmux with sane UTF-8/terminfo defaults.
- `zterminfo-install` installs romkatv's terminfo set into `~/.terminfo`.
- `zssh host [command]` teleports this zsh config plus the Antidote plugin cache, installs terminfo best-effort, sets `ZDOTDIR`/`ANTIDOTE_HOME`, and starts remote zsh. Normal `ssh` is untouched.

Configure with zstyles:

```zsh
zstyle ':zdots:ssh:*' term xterm-256color
zstyle ':zdots:ssh:myhost' send-extra-files ~/.tmux.conf ~/.gitconfig
```

## Lazy-loaded tools

These tools are zero-cost at startup — placeholder functions init on first call:

| Tool | Placeholder commands | Init on first call |
|---|---|---|
| Homebrew | `brew` | `brew shellenv` |
| Cargo/Rust | `cargo`, `rustc`, `rustup` | `source $CARGO_HOME/env` |
| Zoxide | `z`, `zoxide`, `zi` | `zoxide init zsh` |

## Performance tricks

### zwc bytecode (safe usage)

Every sourced `.zsh` file can be compiled to adjacent `.zwc` bytecode via `zcompile`. zsh uses the `.zwc` only when it is newer than the source. It does not auto-recompile; run `recompile` after edits.

**The one footgun:** `mv` preserves file modification time.

```zsh
# ❌ BROKEN: revert with mv — stale .zwc wins
cp config/00-opts.zsh config/00-opts.bak
vi config/00-opts.zsh        # edit
recompile && exec zsh         # oops, that broke things
mv config/00-opts.bak config/00-opts.zsh  # mv preserves old mtime
exec zsh                      # ❌ loads stale bytecode!

# ✅ FIX: touch after mv
mv config/00-opts.bak config/00-opts.zsh
touch config/00-opts.zsh      # update mtime so stale bytecode is ignored
recompile && exec zsh         # ✅ loads fresh bytecode
```

Or just use `cp` instead of `mv` to revert — `cp` updates mtime.

Run `recompile` anytime to regenerate `.zshrc`, `.zstyles`, `.zsh_plugins.zsh`, and all `config/*.zsh` bytecode.

### `ZSH_AUTOSUGGEST_MANUAL_REBIND=1`

Without this, autosuggestions rebinds every ZLE widget on **every precmd** — that's hundreds of `zle -N` calls per command. Setting this flag disables automatic rebinding, saving ~45 ms per command cycle. You must manually call `_zsh_autosuggest_bind_widgets` if you add new widgets after startup.

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

### Widgets

Widget items: forgit, zoxide lazy stubs, clipboard helpers, fancy-ctrl-z, globalias, Alt-Enter magic-enter, pokeget Ctrl+L, history-aux (sqlite + json), fzf history/directory widgets, zsh4humans-style autosuggestion key bindings.

## Secrets

Secrets are platform-agnostic. Preferred files are `$ZDOTDIR/secrets.zsh.gpg`, `$ZDOTDIR/secrets.zsh.age`, then local plaintext `$ZDOTDIR/secrets.zsh` (gitignored, chmod 600). Use `secrets-edit [file]` and `secrets-load [file]`. `.age` defaults to SSH identity `$HOME/.ssh/id_ed25519` / `.pub`; `.gpg` uses symmetric AES256 by default.

## Dependencies

| Tool | Purpose | Install |
|---|---|---|
| zsh ≥ 5.8 | Shell | ships with macOS |
| antidote | Plugin manager | bootstrapped by `.zshrc` |
| starship | Prompt | `brew install starship` |
| fzf | Fuzzy finder | `brew install fzf` |
| zoxide | Smarter cd | `brew install zoxide` |
| eza | `ls` replacement | `brew install eza` |
| fd | Fast `find` | `brew install fd` |
| bat | `cat` replacement | `brew install bat` |
| pokeget | Optional greeting / Ctrl+L art | `brew install pokeget` |
| bwbio | Bitwarden Touch ID | `brew install bwbio` |
| bitwarden-cli | Secrets backend | `brew install bitwarden-cli` |
| sqlite3 | History DB | ships with macOS |
| jq | History JSON | `brew install jq` |
| trash | `rm` replacement | `brew install trash` |
