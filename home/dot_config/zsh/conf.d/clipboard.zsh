# ── clipboard — copyfile/copypath/copybuffer helpers ─────────────
# Adapted from mattmc3/zsh_custom. Ctrl+O = copy command-line buffer.

[[ "$TERM" != 'dumb' ]] || return 0

copyfile() {
  emulate -L zsh
  [[ -z "$1" ]] && { echo "Usage: copyfile <file>"; return 1; }
  [[ -f "$1" ]] || { echo "Error: '$1' is not a valid file."; return 1; }
  cat "$1" | pbcopy
  echo "${(%):-%B$1%b copied to clipboard.}"
}

copypath() {
  local file="${1:-.}"
  [[ $file = /* ]] || file="$PWD/$file"
  print -n "${file:a}" | pbcopy || return 1
  echo "${(%):-%B${file:a}%b copied to clipboard.}"
}

copybuffer() {
  if (( $+commands[pbcopy] || $+functions[pbcopy] || $+aliases[pbcopy] )); then
    printf "%s" "$BUFFER" | pbcopy
  else
    zle -M "pbcopy not found."
  fi
}
zle -N copybuffer
bindkey -M emacs "^O" copybuffer
bindkey -M viins "^O" copybuffer
bindkey -M vicmd "^O" copybuffer
