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

# ── zstyles (sourced early — antidote bootstrap needs them) ──────
[[ -r $ZDOTDIR/.zstyles ]] && source $ZDOTDIR/.zstyles

# ── Antidote plugin bootstrap ────────────────────────────────────
local _plugins_txt=$ZDOTDIR/.zsh_plugins.txt
local _plugins_zsh=$ZDOTDIR/.zsh_plugins.zsh

# Clone antidote if missing
if [[ ! -d $ZDOTDIR/.antidote ]]; then
  git clone --depth 1 https://github.com/mattmc3/antidote $ZDOTDIR/.antidote 2>/dev/null
fi

# Regenerate static plugin file when .txt is newer than .zsh
if [[ ! -f $_plugins_zsh || $_plugins_txt -nt $_plugins_zsh ]]; then
  fpath=($ZDOTDIR/.antidote $fpath)
  autoload -Uz antidote
  antidote bundle <$_plugins_txt >|$_plugins_zsh 2>/dev/null
fi

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
