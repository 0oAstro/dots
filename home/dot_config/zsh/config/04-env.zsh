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
  # trash-cli is keg-only (not symlinked); prepend so it beats /usr/bin/trash
  [[ -d $HOMEBREW_PREFIX/opt/trash-cli/bin ]] && path[1,0]=($HOMEBREW_PREFIX/opt/trash-cli/bin)
fi

# ── Secrets ──────────────────────────────────────────────────────
# Canonical encrypted file: $ZDOTDIR/.zshrc.local.age
# Secret file should contain zsh exports, e.g. export FOO=bar.
_zdots_source_secrets() {
  emulate -L zsh; setopt no_aliases
  local enc="$ZDOTDIR/.zshrc.local.age"
  local key="$HOME/.config/age/keys.txt"
  local out
  [[ -r $enc ]] || return 0
  [[ -r $key ]] || return 1
  (( $+commands[age] )) || return 1
  out=$(age -d -i "$key" -- "$enc") || return 1
  source /dev/stdin <<<"$out"
}
_zdots_source_secrets

secrets-load() { _zdots_source_secrets; }

secrets-edit() {
  emulate -L zsh; setopt no_aliases
  local enc="$ZDOTDIR/.zshrc.local.age"
  local key="$HOME/.config/age/keys.txt"
  local plain recipient

  [[ -r $key ]] || { print -ru2 "secrets-edit: age key $key not found"; return 1; }
  (( $+commands[age] )) || { print -ru2 'secrets-edit: age not found'; return 127; }
  (( $+commands[age-keygen] )) || { print -ru2 'secrets-edit: age-keygen not found'; return 127; }
  [[ -n $EDITOR ]] || { print -ru2 'secrets-edit: EDITOR is not set'; return 1; }

  umask 077
  plain=$(command mktemp /tmp/.zshrc.local.XXXXXX) || return 1
  {
    [[ -r $enc ]] && age -d -i "$key" -- "$enc" >| "$plain" 2>/dev/null
    "$EDITOR" "$plain" || return
    recipient=$(age-keygen -y "$key") || return
    age -r "$recipient" -o "$enc" "$plain" || return
    chmod 600 "$enc" 2>/dev/null || true
  } always {
    command rm -f -- "$plain"
  }
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

secrets-encrypt-age() {
  emulate -L zsh; setopt no_aliases
  local plain="$ZDOTDIR/.zshrc.local"
  local out="$ZDOTDIR/.zshrc.local.age"
  local key="$HOME/.config/age/keys.txt"
  local recipient
  [[ -r $plain ]] || { print -ru2 "missing $plain"; return 1; }
  [[ -r $key ]] || { print -ru2 "secrets-encrypt-age: age key $key not found"; return 1; }
  (( $+commands[age] )) || { print -ru2 'secrets-encrypt-age: age not found'; return 127; }
  (( $+commands[age-keygen] )) || { print -ru2 'secrets-encrypt-age: age-keygen not found'; return 127; }
  recipient=$(age-keygen -y "$key") || return
  age -r "$recipient" -o "$out" "$plain" && chmod 600 "$out" 2>/dev/null || true
}
