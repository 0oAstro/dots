# Shell options, history, key bindings, fpath, and autoloaded functions.
#

setopt NO_FLOW_CONTROL
setopt NO_PROMPT_SP
setopt AUTO_CD
setopt EXTENDED_HISTORY
# Write completed commands with elapsed time; do not import history from peers.
setopt INC_APPEND_HISTORY_TIME
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
# Swap +/- so the `1`..`9` aliases mean "N directories back" rather than
# "Nth from the bottom of the stack", which shifts as the stack grows.
setopt PUSHD_MINUS

HISTFILE=$XDG_STATE_HOME/zsh/history
HISTSIZE=100000
SAVEHIST=100000

bindkey -e

fpath=(
  "$ZDOTDIR/functions"
  ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh/site-functions}
  /usr/local/share/zsh/site-functions
  /usr/share/zsh/site-functions
  $fpath
)

autoload -Uz "$ZDOTDIR"/functions/[^_]*(N.:t)
