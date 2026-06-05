#!/bin/zsh
#
# 04-env.zsh — Environment, secrets, FZF, XDG, PATH, Bitwarden, SPA
#

# ── Environment ──────────────────────────────────────────────────
export CLICOLOR=1
export DIRENV_LOG_FORMAT=""
export PROJECTS=$HOME/Developer
[[ $OS == macos ]] && export SSH_AUTH_SOCK=$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
[[ $OS == macos ]] && export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home

# ── Secrets (cached from Keychain) ──────────────────────────────
local _sec_cache=$XDG_CACHE_HOME/zsh/secrets-cache.zsh
[[ -r $_sec_cache ]] && source $_sec_cache
export TAILSCALE_TAILNET=kitty-armadillo.ts.net

# ── FZF ─────────────────────────────────────────────────────────
export FZF_CTRL_T_OPTS="--preview 'bat --color=always {}'"
export FZF_ALT_C_OPTS="--preview 'eza --all --color=always --tree --level=2 {}'"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

# ── XDG apps ────────────────────────────────────────────────────
export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
export GNUPGHOME=$XDG_DATA_HOME/gnupg

# ── Path additions ──────────────────────────────────────────────
[[ -d $HOMEBREW_PREFIX/opt/macos-trash/bin ]] && path+=($HOMEBREW_PREFIX/opt/macos-trash/bin)
[[ -d $HOMEBREW_PREFIX/opt/postgresql@18/bin ]] && path+=($HOMEBREW_PREFIX/opt/postgresql@18/bin)
[[ -d /Applications/IINA.app/Contents/MacOS ]] && path+=(/Applications/IINA.app/Contents/MacOS)

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
