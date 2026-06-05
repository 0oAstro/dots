#!/bin/zsh
#
# .zshrc — Zsh interactive shell configuration
#

# ── Powerlevel10k instant prompt (must be at the very top) ──────
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Rosé Pine colors ─────────────────────────────────────────────
source $ZDOTDIR/lib/rose-pine/rose-pine.plugin.zsh

# ── Autoload functions ───────────────────────────────────────────
fpath=($ZDOTDIR/functions $fpath)
autoload -Uz $ZDOTDIR/functions/[^_]*(N.:t)

# ── Antidote plugin manager ──────────────────────────────────────
source $ZDOTDIR/lib/antidote-fast.zsh

# ── Ensure p10k gitstatus submodule is initialized ───────────────
() {
  local gs_dir="${ANTIDOTE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/antidote}/github.com/romkatv/powerlevel10k/gitstatus"
  [[ -d "$gs_dir" ]] || return
  if [[ ! -e "$gs_dir/usrbin/gitstatusd" ]]; then
    git -C "$gs_dir/.." submodule update --init --depth 1 gitstatus 2>/dev/null
  fi
}

# ── zstyles ──────────────────────────────────────────────────────
[[ -r $ZDOTDIR/.zstyles ]] && source $ZDOTDIR/.zstyles

# ── p10k: load config and finalize prompt ────────────────────────
[[ -r $ZDOTDIR/.p10k.zsh ]] && source $ZDOTDIR/.p10k.zsh
(( ! ${+functions[p10k]} )) || p10k finalize

# ── Source conf.d snippets ───────────────────────────────────────
for f in $ZDOTDIR/conf.d/*.zsh(N); do
  source "$f"
done

# ── Local overrides ──────────────────────────────────────────────
[[ -r $HOME/.local/config/zsh/.zshrc.local ]] && source $HOME/.local/config/zsh/.zshrc.local

# ── Never start in root ──────────────────────────────────────────
[[ "$PWD" != "/" ]] || cd

true
