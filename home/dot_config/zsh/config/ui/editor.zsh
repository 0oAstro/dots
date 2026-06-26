# ZLE editor behavior and key bindings.

function fancy-ctrl-z {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER="fg"
    zle accept-line -w
  else
    zle push-input -w
    zle clear-screen -w
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

accept-full-suggestion() {
  if [[ -n $POSTDISPLAY ]]; then
    BUFFER="$BUFFER$POSTDISPLAY"
    POSTDISPLAY=""
    zle end-of-line
  else
    zle forward-char
  fi
}
zle -N accept-full-suggestion
bindkey -M emacs '^[[C' accept-full-suggestion
bindkey -M emacs '^[OC' accept-full-suggestion
bindkey -M emacs '^E' end-of-line

_pokeget_clear() {
  clear
  pokeget random --hide-name 2>/dev/null
  zle reset-prompt
}
zle -N _pokeget_clear
bindkey '^L' _pokeget_clear

bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey -M emacs '^[[1;9D' beginning-of-line
bindkey -M emacs '^[[1;9C' end-of-line
bindkey -M emacs '^[[D' backward-char
bindkey -M emacs '^[[3;5~' kill-word
bindkey -M emacs '^[[3;3~' kill-word
bindkey -M emacs '^?' backward-delete-char
bindkey -M emacs '^H' backward-delete-char
