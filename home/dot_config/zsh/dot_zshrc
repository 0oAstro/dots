#!/bin/zsh
#
# .zshrc — Zsh interactive shell entry point
# Sources modular config/ files. zsh auto-loads .zwc bytecode when compiled.
#
# ⚠️  After editing config/*.zsh, run `recompile` (or `exec zsh` — zsh recompiles
#     automatically when source is newer than .zwc). If you need to REVERT with mv,
#     run `touch` on the restored file afterward (mv preserves mtime, fooling zsh).
#
#     Safe:  cp .zshrc.bak .zshrc          ← cp updates mtime ✅
#     Safe:  mv .zshrc.bak .zshrc && touch .zshrc  ← touch fixes mtime ✅
#     Broken: mv .zshrc.bak .zshrc          ← stale .zwc wins ❌
#

# ── Powerlevel10k instant prompt (MUST BE FIRST) ────────────────
if [[ -r ${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source ${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh
fi

# ── Pokemon greeting (after instant prompt, before config loading) ──
pokeget random --hide-name 2>/dev/null

# ── Modular config (zsh auto-loads .zwc bytecode when available) ──
local _cfg=$ZDOTDIR/config
source $_cfg/00-opts.zsh
source $_cfg/01-plugins.zsh
source $_cfg/02-theme.zsh
source $_cfg/03-completions.zsh
source $_cfg/04-env.zsh
source $_cfg/05-aliases.zsh
source $_cfg/06-funcs.zsh
source $_cfg/07-deferred.zsh
source $_cfg/08-prompt.zsh

# ── Recompile helper ─────────────────────────────────────────────
# Run `recompile` after editing config/*.zsh to regenerate .zwc files
alias recompile='for f in $ZDOTDIR/config/*.zsh(N); do zcompile $f && echo "✓ ${f:t}"; done'

true
