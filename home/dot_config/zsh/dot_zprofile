#!/bin/zsh
#
# .zprofile — sourced for login shells only
#

export SHELL_SESSIONS_DISABLE=1
export EDITOR=${EDITOR:-nvim}
export VISUAL=${VISUAL:-code}

# ── Ensure XDG_RUNTIME_DIR exists (only in login shell — rare) ─
[[ -d $XDG_RUNTIME_DIR ]] || mkdir -p $XDG_RUNTIME_DIR 2>/dev/null
[[ -O $XDG_RUNTIME_DIR ]] && chmod 700 $XDG_RUNTIME_DIR 2>/dev/null
