copybuffer() {
  printf "%s" "$BUFFER" | pbcopy
}
zle -N copybuffer
bindkey -M emacs "^O" copybuffer
