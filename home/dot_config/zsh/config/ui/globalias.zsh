# Fish-like alias expansion and magic-enter behavior.

magic-enter-cmd() {
  local cmd
  zstyle -s ':zdots:magic-enter' command cmd || cmd=ls
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    zstyle -s ':zdots:magic-enter' git-command cmd || cmd='git status -sb'
  fi
  echo $cmd
}

_zdots_magic_enter() {
  [[ -n $BUFFER || $CONTEXT != start ]] && return
  BUFFER=$(magic-enter-cmd)
}

typeset -ga _zdots_accept_line_hook
_zdots_accept_line_hook=(_zdots_magic_enter)

_zdots_accept_line() {
  local hook
  for hook in $_zdots_accept_line_hook; do
    $hook
  done
  zle .accept-line
}
zle -N accept-line _zdots_accept_line

typeset -gA _globalias_noexpand
() {
  local -a words
  local word
  zstyle -a ':zdots:globalias' noexpand words || words=(ls grep gpg vi e z 0 1 2 3 4 5 6 7 8 9)
  for word in "${words[@]}"; do
    _globalias_noexpand[$word]=1
  done
}

_globalias_expand_word() {
  local word=${${(Az)LBUFFER}[-1]}
  (( $+_globalias_noexpand[$word] )) && return
  (( $+galiases[$word] || ! $+commands[$word] )) && zle _expand_alias
}

globalias-space() {
  _globalias_expand_word
  zle self-insert
}
zle -N globalias-space

globalias-accept() {
  _globalias_expand_word
  zle accept-line
}
zle -N globalias-accept

local keymap
for keymap in emacs viins; do
  bindkey -M "$keymap" ' ' globalias-space
  bindkey -M "$keymap" '\e ' magic-space
  bindkey -M "$keymap" '^M' globalias-accept
done
bindkey -M isearch ' ' magic-space

accept-line-plain() {
  zle accept-line
}
zle -N accept-line-plain
bindkey -M emacs '^[^M' accept-line-plain
bindkey -M viins '^[^M' accept-line-plain
bindkey -M isearch '^[^M' accept-line-plain

unset keymap
