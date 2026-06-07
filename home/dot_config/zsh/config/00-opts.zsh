#!/bin/zsh
#
# 00-opts.zsh — Shell options, history, key bindings, fpath, fzf
#

# ── Shell options ────────────────────────────────────────────────
setopt NO_FLOW_CONTROL NO_PROMPT_SP AUTO_CD EXTENDED_HISTORY INC_APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY

# ── History ──────────────────────────────────────────────────────
HISTFILE=$XDG_STATE_HOME/zsh/history
HISTSIZE=100000
SAVEHIST=100000

# ── Key bindings (before plugins) ────────────────────────────────
bindkey -e
bindkey '^I' menu-complete
bindkey '^[[Z' reverse-menu-complete

# ── fpath + autoload ─────────────────────────────────────────────
fpath=(
  $ZDOTDIR/functions
  $ANTIDOTE_HOME/github.com/zsh-users/zsh-completions/src
  ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh/site-functions}
  /usr/local/share/zsh/site-functions
  /usr/share/zsh/site-functions
  $fpath
)

autoload -Uz $ZDOTDIR/functions/[^_]*(N.:t)

# ── fzf key-bindings (real line editor only) ─────────────────────
# Skipping zsh -i -c avoids Homebrew fzf's readonly `zle` restore warning.
if [[ -t 0 && -t 1 && -z ${ZSH_EXECUTION_STRING:-} ]]; then
  local _fzf_kb
  for _fzf_kb in \
    ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh} \
    /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
    /usr/local/opt/fzf/shell/key-bindings.zsh \
    /usr/share/fzf/key-bindings.zsh \
    /usr/share/doc/fzf/examples/key-bindings.zsh; do
    [[ -r $_fzf_kb ]] && { source $_fzf_kb; break; }
  done
  unset _fzf_kb
fi
