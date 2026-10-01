# Terminal configs launch Herdr; zsh only reports pane state.

[[ ${HERDR_ENV:-} == 1 ]] || return 0
autoload -Uz add-zsh-hook

# Herdr consumes OSC 7 cwd reports and OSC 2 titles: no API process per prompt.
_zdots_herdr_cwd() {
  emulate -L zsh
  local LC_ALL=C char encoded uri
  for char in ${(s::)PWD}; do
    case $char in
      [a-zA-Z0-9/._~-]) uri+=$char ;;
      *) printf -v encoded '%%%02X' "'$char"; uri+=$encoded ;;
    esac
  done
  print -rn -- $'\e]7;file://'"${HOST%%.*}$uri"$'\e\\'
}

_zdots_herdr_title() {
  local title=${PWD:t}
  print -rn -- $'\e]2;'"${title//[[:cntrl:]]/}"$'\a'
}

add-zsh-hook chpwd _zdots_herdr_cwd
add-zsh-hook precmd _zdots_herdr_title
_zdots_herdr_cwd
