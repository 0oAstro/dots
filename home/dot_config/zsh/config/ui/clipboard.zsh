# Clipboard helpers.

local clip_cmd=pbcopy

copyfile() {
  [[ -z $1 ]] && { echo "Usage: copyfile <file>"; return 1; }
  [[ -f $1 ]] || { echo "Error: '$1' is not a valid file."; return 1; }
  eval "$clip_cmd" < "$1"
  echo "${(%):-%B$1%b copied to clipboard.}"
}

copypath() {
  local file=${1:-.}
  [[ $file = /* ]] || file=$PWD/$file
  print -n "${file:a}" | eval "$clip_cmd"
  echo "${(%):-%B${file:a}%b copied to clipboard.}"
}

copybuffer() {
  printf "%s" "$BUFFER" | eval "$clip_cmd"
}
zle -N copybuffer
bindkey -M emacs "^O" copybuffer
bindkey -M viins "^O" copybuffer
bindkey -M vicmd "^O" copybuffer
