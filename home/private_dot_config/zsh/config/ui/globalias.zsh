# Fish-like alias expansion and magic-enter behavior.

_zdots_accept_line() {
  if [[ -z $BUFFER && $CONTEXT == start ]]; then
    if command git rev-parse --is-inside-work-tree &>/dev/null; then
      BUFFER='git status -sb'
    else
      BUFFER=ls
    fi
  fi
  zle .accept-line
}
zle -N accept-line _zdots_accept_line

_globalias_expand_word() {
  local word=${${(Az)LBUFFER}[-1]}
  case $word in ls|grep|vi|e|z|[0-9]) return ;; esac
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

bindkey -M emacs ' ' globalias-space
bindkey -M emacs '\e ' magic-space
bindkey -M emacs '^M' globalias-accept
bindkey -M isearch ' ' magic-space

accept-line-plain() {
  zle .accept-line
}
zle -N accept-line-plain
bindkey -M emacs '^[^M' accept-line-plain
bindkey -M isearch '^[^M' accept-line-plain

unset keymap
