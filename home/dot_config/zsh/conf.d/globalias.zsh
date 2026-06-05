# ── globalias — Fish-like abbreviation expansion ────────────────
# Press Space after an alias to expand it. Enter expands then accepts.
# Alt+Space inserts a literal space without expanding.
# Adapted from mattmc3/zsh_custom

typeset -gA _globalias_noexpand

# Words to never expand (real commands you type regularly)
() {
  local -a _words
  local _w
  zstyle -a ':zsh:plugin:globalias' noexpand '_words' \
    || _words=(ls grep gpg vi e z 0 1 2 3 4 5 6 7 8 9)
  for _w in "${_words[@]}"; do
    _globalias_noexpand[$_w]=1
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
  zle .accept-line
}
zle -N globalias-accept

# Bind: Space expands, Alt+Space literal, Enter expands+accepts
local _gkm
for _gkm in emacs viins; do
  bindkey -M "$_gkm" ' '  globalias-space
  bindkey -M "$_gkm" '\e ' magic-space
  bindkey -M "$_gkm" '^M' globalias-accept
done
bindkey -M isearch ' ' magic-space
unset _gkm
