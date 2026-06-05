# ── magic-enter — default command on empty Enter ─────────────────
# Press Enter on empty line → ls (or git status inside repos).
# Adapted from mattmc3/zsh_custom (no hook system dependency).

function magic-enter-cmd {
  local cmd
  zstyle -s ':zsh:plugin:magic-enter' command cmd ||
    cmd="${MAGIC_ENTER_OTHER_COMMAND:-ls}"

  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    zstyle -s ':zsh:plugin:magic-enter' git-command cmd ||
      cmd="${MAGIC_ENTER_GIT_COMMAND:-git status -sb}"
  fi
  echo $cmd
}

function magic-enter {
  if [[ -n "$BUFFER" || "$CONTEXT" != start ]]; then
    zle .accept-line
    return
  fi
  BUFFER=$(magic-enter-cmd)
  zle .accept-line
}
zle -N magic-enter
bindkey -M emacs '^M' magic-enter
bindkey -M viins '^M' magic-enter
