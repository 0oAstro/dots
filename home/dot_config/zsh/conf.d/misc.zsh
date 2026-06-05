# ── Misc options ─────────────────────────────────────────────────
setopt noflowcontrol AUTO_CD

# ── Bitwarden CLI ────────────────────────────────────────────────
bw() { bwbio "$@"; }
load-secret() {
  local value; value=$(bw get item "$1" 2>/dev/null | jq -r '.notes // empty')
  if [[ -n "$value" && "$value" != "null" ]]; then
    export "$1"="$value"; echo "✅  $1"
  else
    echo "❌  $1 — not found (bw unlocked? item exists?)" >&2; return 1
  fi
}
load-secrets() { for name in "$@"; do load-secret "$name"; done }

# ── SPA (tmux/mosh remote) ──────────────────────────────────────
spa() {
  local host="${USER}@spa" session="main"
  if (( $# > 0 )); then
    case "$1" in
      --) shift; (( $# == 0 )) && { echo "usage: spa -- <command>" >&2; return 2; }
          mosh --predict=experimental --predict-overwrite "$host" -- "$@"; return $? ;;
      ssh) ssh -tt "$host"; return $? ;;
      *) session="$1" ;;
    esac
  fi
  mosh --predict=experimental --predict-overwrite "$host" -- tmux new-session -A -s "$session"
}

# ── pokeget (fish-style greeting + Ctrl+L pokemon) ─────────────
typeset -g _zsh_greeting_done=0
# Only greet after p10k has finished instant prompt phase
_zsh_pokeget_greeting() {
  (( _zsh_greeting_done )) && return
  _zsh_greeting_done=1
  pokeget random --hide-name 2>/dev/null
}
precmd_functions+=(_zsh_pokeget_greeting)

_pokeget_clear() { clear; pokeget random --hide-name; zle reset-prompt; }
zle -N _pokeget_clear
