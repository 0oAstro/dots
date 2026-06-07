#!/bin/zsh
#
# 06-funcs.zsh — Shell scripting helpers
#

die()  { warn "$@"; exit "${ERR:-1}"; }
say()  { printf '%s\n' "$@"; }
warn() { say "$@" >&2; }

bak() {
  local now f
  now=$(date +"%Y%m%d-%H%M%S")
  for f in "$@"; do
    [[ -e "$f" ]] || { echo "file not found: $f" >&2; continue; }
    cp -R "$f" "$f".$now.bak
  done
}

touchf() {
  [[ -n "$1" ]] && [[ ! -f "$1" ]] && mkdir -p "$1:h" && touch "$1"
}

up() {
  local parents=${1:-1}
  (( parents > 0 )) || { print -ru2 "up: expecting a numeric parameter"; return 1; }
  local i dotdot=".."
  for ((i = 1; i < parents; i++)); do dotdot+="/.."; done
  cd $dotdot
}

weather() { curl "http://wttr.in/$1"; }

colormap() {
  for i in {0..255}; do
    print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}
  done
}

# eza override (better ls)
ls() {
  if (( $+commands[eza] )); then eza -laH --icons --git --color=always "$@"
  else command ls -la "$@"
  fi
}

# Age-encrypted secrets helper
# Decrypts .zshrc.local.age, opens in $EDITOR, re-encrypts, commits, pushes.
edit-secrets() {
  local _key="${AGE_IDENTITY:-$HOME/.config/age/keys.txt}"
  local _enc="$ZDOTDIR/.zshrc.local.age"
  local _plain="${TMPDIR:-/tmp}/.zshrc.local.$$"

  [[ -r $_enc ]] || { echo >&2 "edit-secrets: $_enc not found"; return 1; }
  [[ -r $_key ]]  || { echo >&2 "edit-secrets: age key $_key not found"; return 1; }

  age -d -i $_key $_enc > $_plain
  ${EDITOR:-vim} $_plain

  local _pubkey=$(age-keygen -y $_key 2>/dev/null)
  age -r "$_pubkey" -o $_enc $_plain 2>/dev/null
  rm -f $_plain

  (cd $ZDOTDIR && git add .zshrc.local.age && git commit -m "update secrets" && git push)
}
