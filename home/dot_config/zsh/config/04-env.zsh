#!/bin/zsh
#
# 04-env.zsh — Environment, secrets, FZF, XDG, PATH, remote helpers
#

# ── Environment ──────────────────────────────────────────────────
export CLICOLOR=1
export DIRENV_LOG_FORMAT=""
export PROJECTS=${PROJECTS:-$HOME/Developer}
export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export TAILSCALE_TAILNET=${TAILSCALE_TAILNET:-kitty-armadillo.ts.net}
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config

# Platform-specific optional paths/sockets.
if [[ $OS == macos ]]; then
  local _bw_sock=$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
  [[ -S $_bw_sock ]] && export SSH_AUTH_SOCK=$_bw_sock
  [[ -d /Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home ]] && \
    export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home
  # trash-cli is keg-only (not symlinked); add its bin to PATH
  [[ -d $HOMEBREW_PREFIX/opt/trash-cli/bin ]] && path+=($HOMEBREW_PREFIX/opt/trash-cli/bin)
fi

# ── Secrets ──────────────────────────────────────────────────────
# Preferred files, in order:
#   $ZDOTDIR/secrets.zsh.gpg  - decrypted with gpg -dq
#   $ZDOTDIR/secrets.zsh.age  - decrypted with age -d -i ~/.ssh/id_ed25519
#   $ZDOTDIR/secrets.zsh      - plaintext local fallback (gitignored; chmod 600)
# Secret files should contain zsh exports, e.g. export FOO=bar.
export ZDOTS_SECRETS_FILE=${ZDOTS_SECRETS_FILE:-}
_zdots_source_secrets() {
  emulate -L zsh; setopt no_aliases
  local f=${1:-$ZDOTS_SECRETS_FILE} out
  if [[ -z $f ]]; then
    if [[ -r $ZDOTDIR/secrets.zsh.gpg ]]; then f=$ZDOTDIR/secrets.zsh.gpg
    elif [[ -r $ZDOTDIR/secrets.zsh.age ]]; then f=$ZDOTDIR/secrets.zsh.age
    elif [[ -r $ZDOTDIR/secrets.zsh ]]; then f=$ZDOTDIR/secrets.zsh
    else return 0
    fi
  fi
  case $f in
    *.gpg) (( $+commands[gpg] )) || return 1; out=$(gpg -dq -- "$f") || return 1; source /dev/stdin <<<"$out" ;;
    *.age) (( $+commands[age] )) || return 1; out=$(age -d -i ${ZDOTS_SECRETS_KEY:-$HOME/.ssh/id_ed25519} -- "$f") || return 1; source /dev/stdin <<<"$out" ;;
    *)     [[ -r $f ]] && source "$f" ;;
  esac
}
_zdots_source_secrets

secrets-load() { _zdots_source_secrets "$@"; }
secrets-edit() {
  emulate -L zsh; setopt no_aliases
  local plain=${TMPDIR:-/tmp}/zdots-secrets.$$ f=${1:-${ZDOTS_SECRETS_FILE:-$ZDOTDIR/secrets.zsh.gpg}}
  umask 077
  case $f in
    *.gpg) [[ -r $f ]] && gpg -dq -- "$f" >| "$plain" 2>/dev/null; ${EDITOR:-vi} "$plain"; gpg -c --cipher-algo AES256 -o "$f" "$plain" ;;
    *.age) [[ -r $f ]] && age -d -i ${ZDOTS_SECRETS_KEY:-$HOME/.ssh/id_ed25519} -- "$f" >| "$plain" 2>/dev/null; ${EDITOR:-vi} "$plain"; age -R ${ZDOTS_SECRETS_RECIPIENTS:-$HOME/.ssh/id_ed25519.pub} -o "$f" "$plain" ;;
    *)     ${EDITOR:-vi} "$f"; chmod 600 "$f" 2>/dev/null ;;
  esac
  command rm -f "$plain"
}

# ── FZF ─────────────────────────────────────────────────────────
local _fzf_preview_file='bat --color=always --style=numbers --line-range=:160 {} 2>/dev/null || sed -n "1,160p" {} 2>/dev/null'
local _fzf_preview_dir='eza --all --color=always --tree --level=2 {} 2>/dev/null || ls -la {} 2>/dev/null'
export FZF_CTRL_T_OPTS="--preview '$_fzf_preview_file'"
export FZF_ALT_C_OPTS="--preview '$_fzf_preview_dir'"
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
else
  export FZF_DEFAULT_COMMAND="find . -path './.git' -prune -o -type f -print"
fi
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
unset _fzf_preview_file _fzf_preview_dir

# ── Path additions ──────────────────────────────────────────────
[[ -n ${HOMEBREW_PREFIX:-} && -d $HOMEBREW_PREFIX/opt/postgresql@18/bin ]] && path+=($HOMEBREW_PREFIX/opt/postgresql@18/bin)

# ── Bitwarden CLI ────────────────────────────────────────────────
(( $+commands[bwbio] )) && bw() { bwbio "$@"; }
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

secrets-encrypt-gpg() {
  emulate -L zsh; setopt no_aliases
  local plain=${1:-$ZDOTDIR/secrets.zsh} out=${2:-$ZDOTDIR/secrets.zsh.gpg} recipient=${SECRETS_GPG_RECIPIENT:-}
  [[ -r $plain ]] || { print -ru2 "missing $plain"; return 1; }
  if [[ -n $recipient ]]; then
    gpg --yes --encrypt --recipient "$recipient" --output "$out" "$plain"
  else
    gpg --yes --symmetric --cipher-algo AES256 --output "$out" "$plain"
  fi
  chmod 600 "$out" 2>/dev/null || true
}

secrets-encrypt-age() {
  emulate -L zsh; setopt no_aliases
  local plain=${1:-$ZDOTDIR/secrets.zsh} out=${2:-$ZDOTDIR/secrets.zsh.age} recipients=${ZDOTS_SECRETS_RECIPIENTS:-$HOME/.ssh/id_ed25519.pub}
  [[ -r $plain ]] || { print -ru2 "missing $plain"; return 1; }
  (( $+commands[age] )) || { print -ru2 'secrets-encrypt-age: age not found'; return 127; }
  age -R "$recipients" -o "$out" "$plain" && chmod 600 "$out" 2>/dev/null || true
}
