#!/bin/zsh
#
# 00-opts.zsh — Shell options, history, key bindings, fpath, fzf
#

# ── Skip p10k SSH detection (avoids 8ms `who -m` fork) ──────────
if [[ -n $SSH_CLIENT || -n $SSH_TTY || -n $SSH_CONNECTION ]]; then
  typeset -gix P9K_SSH=1
else
  typeset -gix P9K_SSH=0
fi
typeset -gx _P9K_SSH_TTY=$TTY

# ── Shell options ────────────────────────────────────────────────
setopt NO_FLOW_CONTROL AUTO_CD HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY

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
  $HOME/.config/zsh/functions
  $ANTIDOTE_HOME/github.com/zsh-users/zsh-completions/src
  /opt/homebrew/share/zsh/site-functions
  /usr/local/share/zsh/site-functions
  /usr/share/zsh/site-functions
  $fpath
)
autoload -Uz $HOME/.config/zsh/functions/[^_]*(N.:t)

# ── fzf key-bindings (before FSH so widgets are known) ───────────
local _fzf_kb
for _fzf_kb in \
  /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
  /usr/share/fzf/key-bindings.zsh \
  /usr/share/doc/fzf/examples/key-bindings.zsh; do
  if [[ -r $_fzf_kb ]]; then
    source $_fzf_kb
    break
  fi
done
unset _fzf_kb
