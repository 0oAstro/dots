# Fish-like alias expansion and magic-enter behavior.

magic-enter-cmd() {
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    print -r -- 'git status -sb'
  else
    print -r -- ls
  fi
}

_zdots_magic_enter() {
  [[ -n $BUFFER || $CONTEXT != start ]] && return
  BUFFER=$(magic-enter-cmd)
}

_zdots_accept_line() {
  _zdots_magic_enter
  zle .accept-line
}
zle -N accept-line _zdots_accept_line

_globalias_expand_word() {
  local word=${${(Az)LBUFFER}[-1]}
  case $word in ls|grep|gpg|vi|e|z|[0-9]) return ;; esac
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
  zle .accept-line
}
zle -N accept-line-plain
bindkey -M emacs '^[^M' accept-line-plain
bindkey -M viins '^[^M' accept-line-plain
bindkey -M isearch '^[^M' accept-line-plain

unset keymap
