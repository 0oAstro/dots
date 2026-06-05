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

# ── pokeget (fish-style greeting on startup) ──────────────────
# Deferred via sched so it runs AFTER p10k prompt is ready.
() {
  zmodload zsh/sched 2>/dev/null || return
  sched +0:05 'pokeget random --hide-name 2>/dev/null'
}

_pokeget_clear() { clear; pokeget random --hide-name; zle reset-prompt; }
zle -N _pokeget_clear
