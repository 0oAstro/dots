# Clipboard helpers.

[[ $OSTYPE == darwin* ]] || return

copyfile() {
  [[ -z $1 ]] && { echo "Usage: copyfile <file>"; return 1; }
  [[ -f $1 ]] || { echo "Error: '$1' is not a valid file."; return 1; }
  pbcopy < "$1"
  echo "${(%):-%B$1%b copied to clipboard.}"
}

copypath() {
  local file=${1:-.}
  [[ $file = /* ]] || file=$PWD/$file
  print -n "${file:a}" | pbcopy
  echo "${(%):-%B${file:a}%b copied to clipboard.}"
}

copybuffer() {
  printf "%s" "$BUFFER" | pbcopy
}
zle -N copybuffer
bindkey -M emacs "^O" copybuffer
bindkey -M viins "^O" copybuffer
bindkey -M vicmd "^O" copybuffer
