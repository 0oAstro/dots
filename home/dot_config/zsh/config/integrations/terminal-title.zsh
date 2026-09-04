# Dynamic titles for persistent aardvark/zmx shells.
autoload -Uz add-zsh-hook

_aardvark_title_precmd() {
  print -rn -- $'\e]2;'"$ZMX_SESSION"$'\a'
}

_aardvark_title_preexec() {
  local -a words
  words=(${(z)1})
  local command=${words[1]:t}
  [[ -n $command ]] || return 0
  print -rn -- $'\e]2;'"$command"$'\a'
}

add-zsh-hook precmd _aardvark_title_precmd
add-zsh-hook preexec _aardvark_title_preexec
_aardvark_title_precmd
