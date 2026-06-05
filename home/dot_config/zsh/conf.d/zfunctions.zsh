# ── zfunctions — Fish-like function management ───────────────────
# funcsave: persist a shell function to $ZDOTDIR/functions/
# funced:   edit or create a function file
# funcfresh: reload a function from its file
# Adapted from mattmc3/zsh_custom

function zfuncdir {
  emulate -L zsh; setopt local_options
  local zfuncd
  zstyle -s ':zsh:plugin:zfunctions' directory zfuncd \
    || zfuncd="${ZFUNCDIR:-${ZDOTDIR:-$HOME/.config/zsh}/functions}"
  echo "${~zfuncd}"
}

function autoload-dir {
  local zdir
  local -a zautoloads
  for zdir in $@; do
    zdir="${zdir:A}"
    [[ -d "$zdir" ]] || continue
    fpath=("$zdir" $fpath)
    zautoloads=($zdir/*~_*(N.:t))
    (( $#zautoloads > 0 )) && autoload -Uz $zautoloads
  done
}

function funcsave {
  emulate -L zsh; setopt local_options
  local zfuncd=$(zfuncdir)

  if (( $# == 0 )); then
    echo >&2 "funcsave: Expected at least 1 arg, got 0."
    return 1
  elif ! typeset -f "$1" > /dev/null; then
    echo >&2 "funcsave: Unknown function '$1'."
    return 1
  elif [[ ! -d "$zfuncd" ]]; then
    echo >&2 "funcsave: Directory not found '$zfuncd'."
    return 1
  fi

  autoload +X "$1" > /dev/null
  type -f "$1" | awk 'NR>2 {print prev} {gsub(/^\t/, "", $0); prev=$0}' >| "$zfuncd/$1"
}

function funced {
  emulate -L zsh; setopt local_options
  local zfuncd=$(zfuncdir)

  if (( $# == 0 )); then
    echo >&2 "funced: Expected at least 1 arg, got 0."
    return 1
  elif [[ ! -d "$zfuncd" ]]; then
    echo >&2 "funced: Directory not found '$zfuncd'."
    return 1
  fi

  if [[ ! -f "$zfuncd/$1" ]]; then
    printf '%s\n' '#!/bin/zsh' "#function $1 {" "" "#}" "#$1 \"\$@\"" > "$zfuncd/$1"
    autoload -Uz "$zfuncd/$1"
  fi

  ${VISUAL:-${EDITOR:-vim}} "$zfuncd/$1"
}

function funcfresh {
  emulate -L zsh; setopt local_options
  if (( $# == 0 )); then
    echo >&2 "funcfresh: Expecting function argument."
    return 1
  elif ! (( $+functions[$1] )); then
    echo >&2 "funcfresh: Function not found '$1'."
    return 1
  fi
  unfunction $1
  autoload -Uz $1
}
