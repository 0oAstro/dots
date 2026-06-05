#!/bin/zsh
#
# .zshrc — Zsh interactive shell configuration
# Optimized for sub-10ms command_lag. Zero-fork philosophy.
#

# ── Powerlevel10k instant prompt (BEFORE ANYTHING ELSE) ──────────
if [[ -r ${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source ${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh
fi

# ── Pokemon greeting (after instant prompt, before plugin loading) ──
pokeget random --hide-name 2>/dev/null

# ── Skip p10k SSH detection (avoids 8ms `who -m` fork) ──────────
# Pre-set P9K_SSH so _p9k_init_ssh returns immediately.
# In an actual SSH session, SSH_CLIENT/SSH_TTY/SSH_CONNECTION are set by sshd.
if [[ -n $SSH_CLIENT || -n $SSH_TTY || -n $SSH_CONNECTION ]]; then
  typeset -gix P9K_SSH=1
else
  typeset -gix P9K_SSH=0
fi
typeset -gx _P9K_SSH_TTY=$TTY

# ── Essential shell options (before anything) ────────────────────
setopt NO_FLOW_CONTROL AUTO_CD HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY

# ── History ──────────────────────────────────────────────────────
HISTFILE=$XDG_STATE_HOME/zsh/history
HISTSIZE=100000
SAVEHIST=100000

# ── Key bindings (before plugins that bind keys) ─────────────────
bindkey -e
bindkey '^I' menu-complete
bindkey '^[[Z' reverse-menu-complete

# ── fpath + autoload (single pass, no duplicates) ────────────────
fpath=(
  $HOME/.config/zsh/functions
  $HOME/Library/Caches/antidote/github.com/zsh-users/zsh-completions/src
  /opt/homebrew/share/zsh/site-functions
  $fpath
)
autoload -Uz $HOME/.config/zsh/functions/[^_]*(N.:t)

# ── fzf key-bindings (before FSH so widgets are known) ─────────────
if [[ -r /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
fi

# ── Antidote: static source only (zero overhead) ─────────────────
local _plugins=$ZDOTDIR/.zsh_plugins.zsh
# Performance: skip autosuggestions widget re-bind on every precmd
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Inhibit autopair auto-init — we'll call it in deferred hook
export AUTOPAIR_INHIBIT_INIT=1
[[ -r $_plugins ]] && source $_plugins
unset AUTOPAIR_INHIBIT_INIT

# ── Rose Pine theme for FSH ──────────────────────────────────────
export TERM16M_THEME=rose-pine
export TERM16M_BASE="25;23;36" TERM16M_SURFACE="31;29;46" TERM16M_OVERLAY="38;35;58"
export TERM16M_MUTED="110;106;134" TERM16M_SUBTLE="144;140;170" TERM16M_TEXT="224;222;244"
export TERM16M_LOVE="235;111;146" TERM16M_GOLD="246;193;119" TERM16M_ROSE="235;188;186"
export TERM16M_PINE="49;116;143" TERM16M_FOAM="156;207;216" TERM16M_IRIS="196;167;231"
export TERM16M_SEL_L="33;32;46" TERM16M_SEL_M="64;61;82" TERM16M_SEL_H="82;79;103"
source $ZDOTDIR/lib/rose-pine/themes/rose-pine.zsh

# ── Completions ─────────────────────────────────────────────────
zstyle ':completion:*' menu select=2
zstyle ':completion:*' group-name '' verbose yes
zstyle ':completion:*' completer _complete _ignored _approximate
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/.zcompcache
_comp_options+=(globdots)
ZSH_COMPDUMP=$XDG_CACHE_HOME/zsh/zcompdump-$HOST

# ── zstyles (from .zstyles file) ────────────────────────────────
[[ -r $ZDOTDIR/.zstyles ]] && source $ZDOTDIR/.zstyles

# ── Environment (interactive only) ───────────────────────────────
export CLICOLOR=1
export DIRENV_LOG_FORMAT=""
export PROJECTS=$HOME/Developer
[[ $OS == macos ]] && export SSH_AUTH_SOCK=$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
[[ $OS == macos ]] && export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home

# ── Secrets (cached, zero-fork) ─────────────────────────────────
local _sec_cache=$XDG_CACHE_HOME/zsh/secrets-cache.zsh
[[ -r $_sec_cache ]] && source $_sec_cache
export TAILSCALE_TAILNET=kitty-armadillo.ts.net

# ── FZF ─────────────────────────────────────────────────────────
export FZF_CTRL_T_OPTS="--preview 'bat --color=always {}'"
export FZF_ALT_C_OPTS="--preview 'eza --all --color=always --tree --level=2 {}'"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

# ── Aliases ─────────────────────────────────────────────────────
alias e=$EDITOR
alias ga="git add" gb="git branch" gc="git commit"
alias gca="git commit --amend" gcm="git commit -m"
alias gco="git checkout" gd="git diff" gds="git diff --staged"
alias gp="git push" gpl="git pull" gl="git log"
alias gr="git rebase" gs="git status --short" gss="git status"
alias md="mkdir -p" rm=trash rrm="command rm"
alias ..="cd .."
alias _=sudo l=ls g=git
alias grep="${aliases[grep]:-grep} --exclude-dir={.git,.vscode}"
alias ping='ping -c 5' vi=vim
alias get=git quit=exit cd..='cd ..' zz=exit
alias ll='ls -lh' la='ls -lAh'
alias timestamp="date '+%Y-%m-%d %H:%M:%S'"
alias datestamp="date '+%Y-%m-%d'"
alias isodate="date +%Y-%m-%dT%H:%M:%S%z"
alias utc="date -u +%Y-%m-%dT%H:%M:%SZ"
alias unixepoch="date +%s"
alias print-fpath='for fp in $fpath; do echo $fp; done; unset fp'
alias print-path='echo $PATH | tr ":" "\n"'
alias print-functions='print -l ${(k)functions[(I)[^_]*]} | sort'
alias zshrc='${EDITOR:-vim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'
alias sedi="sed -i ''"
(( $+commands[python3] )) && ! (( $+commands[python] )) && alias python=python3
(( $+commands[pip3] )) && ! (( $+commands[pip] )) && alias pip=pip3
! (( $+commands[hd] )) && (( $+commands[hexdump] )) && alias hd="hexdump -C"
! (( $+commands[envsubst] )) && alias envsubst="python -c 'import os,sys;[sys.stdout.write(os.path.expandvars(l)) for l in sys.stdin]'"

# ── XDG apps ────────────────────────────────────────────────────
export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
export GNUPGHOME=$XDG_DATA_HOME/gnupg

# ── Path additions (macOS-specific) ─────────────────────────────
path+=(
  $HOMEBREW_PREFIX/opt/macos-trash/bin
  $HOMEBREW_PREFIX/opt/postgresql@18/bin
  /Applications/IINA.app/Contents/MacOS
)

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

# ── SPA ──────────────────────────────────────────────────────────
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

# ── Shell scripting helpers ──────────────────────────────────────
die()  { warn "$@"; exit "${ERR:-1}"; }
say()  { printf '%s\n' "$@"; }
warn() { say "$@" >&2; }
bak()  { local now f; now=$(date +"%Y%m%d-%H%M%S"); for f in "$@"; do [[ -e "$f" ]] || { echo "file not found: $f" >&2; continue; }; cp -R "$f" "$f".$now.bak; done; }
touchf() { [[ -n "$1" ]] && [[ ! -f "$1" ]] && mkdir -p "$1:h" && touch "$1"; }
up() { local parents=${1:-1}; (( parents > 0 )) || { print -ru2 "up: expecting a numeric parameter"; return 1; }; local i dotdot=".."; for ((i = 1; i < parents; i++)); do dotdot+="/.."; done; cd $dotdot; }
weather() { curl "http://wttr.in/$1"; }
colormap() { for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done; }
ls() { eza -laH --icons --git --color=always "$@"; }

# ── Deferred: lazy tool loading + heavy conf.d ───────────────────
# All of this runs AFTER the prompt appears via precmd hook
typeset -g _zush_deferred_done=0
_zush_deferred() {
  (( _zush_deferred_done )) && return
  _zush_deferred_done=1

  # ── autopair (deferred init — saves 4ms) ──
  (( ${+functions[autopair-init]} )) && autopair-init

  # ── forgit (lazy — only load when git/fzf commands are used) ──
  local _forgit=$HOME/Library/Caches/antidote/github.com/wfxr/forgit/forgit.plugin.zsh
  (( ${+commands[fzf]} )) && [[ -r $_forgit ]] && source $_forgit

  # Lazy-load brew (on first `brew` call)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    function brew() {
      unfunction brew
      eval "$(/opt/homebrew/bin/brew shellenv)"
      brew "$@"
    }
  fi

  # Lazy-load cargo env
  if [[ -f $CARGO_HOME/env ]]; then
    function cargo() { unfunction cargo rustc rustup; source $CARGO_HOME/env; cargo "$@"; }
    function rustc() { unfunction cargo rustc rustup; source $CARGO_HOME/env; rustc "$@"; }
    function rustup() { unfunction cargo rustc rustup; source $CARGO_HOME/env; rustup "$@"; }
  fi

  # Lazy-load zoxide
  if (( $+commands[zoxide] )); then
    function z() { unfunction z zoxide zi; eval "$(zoxide init zsh)"; z "$@"; }
    function zoxide() { unfunction z zoxide zi; eval "$(zoxide init zsh)"; zoxide "$@"; }
    function zi() { unfunction z zoxide zi; eval "$(zoxide init zsh)"; zi "$@"; }
    alias cd=z
  fi

  # ── clipboard helpers ──
  local _clip_cmd
  if (( $+commands[pbcopy] )); then _clip_cmd=pbcopy
  elif (( $+commands[wl-copy] )); then _clip_cmd='wl-copy'
  elif (( $+commands[xclip] )); then _clip_cmd='xclip -selection clipboard'
  elif (( $+commands[xsel] )); then _clip_cmd='xsel --clipboard --input'
  fi
  copyfile() { [[ -n "$_clip_cmd" ]] || { echo "No clipboard tool found."; return 1; }; [[ -z "$1" ]] && { echo "Usage: copyfile <file>"; return 1; }; [[ -f "$1" ]] || { echo "Error: '$1' is not a valid file."; return 1; }; cat "$1" | eval $_clip_cmd; echo "${(%):-%B$1%b copied to clipboard.}"; }
  copypath() { local file="${1:-.}"; [[ $file = /* ]] || file="$PWD/$file"; print -n "${file:a}" | eval $_clip_cmd || return 1; echo "${(%):-%B${file:a}%b copied to clipboard.}"; }
  copybuffer() { if [[ -n "$_clip_cmd" ]]; then printf "%s" "$BUFFER" | eval $_clip_cmd; else zle -M "No clipboard tool found."; fi; }
  zle -N copybuffer
  bindkey -M emacs "^O" copybuffer
  bindkey -M viins "^O" copybuffer
  bindkey -M vicmd "^O" copybuffer

  # ── fancy-ctrl-z ──
  function fancy-ctrl-z { if [[ $#BUFFER -eq 0 ]]; then BUFFER="fg"; zle accept-line -w; else zle push-input -w; zle clear-screen -w; fi; }
  zle -N fancy-ctrl-z
  bindkey '^Z' fancy-ctrl-z

  # ── globalias ──
  typeset -gA _globalias_noexpand
  local -a _words=(ls grep gpg vi e z 0 1 2 3 4 5 6 7 8 9)
  local _w; for _w in "${_words[@]}"; do _globalias_noexpand[$_w]=1; done
  _globalias_expand_word() { local word=${${(Az)LBUFFER}[-1]}; (( $+_globalias_noexpand[$word] )) && return; (( $+galiases[$word] || ! $+commands[$word] )) && zle _expand_alias; }
  globalias-space() { _globalias_expand_word; zle self-insert; }
  globalias-accept() { _globalias_expand_word; zle .accept-line; }
  zle -N globalias-space
  zle -N globalias-accept
  local _gkm; for _gkm in emacs viins; do bindkey -M "$_gkm" ' ' globalias-space; bindkey -M "$_gkm" '\e ' magic-space; bindkey -M "$_gkm" '^M' globalias-accept; done
  bindkey -M isearch ' ' magic-space

  # ── magic-enter (overwrites globalias ^M — globalias only uses Space in practice) ──
  function magic-enter-cmd { local cmd; zstyle -s ':zsh:plugin:magic-enter' command cmd || cmd="${MAGIC_ENTER_OTHER_COMMAND:-ls}"; if command git rev-parse --is-inside-work-tree &>/dev/null; then zstyle -s ':zsh:plugin:magic-enter' git-command cmd || cmd="${MAGIC_ENTER_GIT_COMMAND:-git status -sb}"; fi; echo $cmd; }
  function magic-enter { if [[ -n "$BUFFER" || "$CONTEXT" != start ]]; then zle .accept-line; return; fi; BUFFER=$(magic-enter-cmd); zle .accept-line; }
  zle -N magic-enter
  bindkey -M emacs '^M' magic-enter
  bindkey -M viins '^M' magic-enter

  # ── Ctrl+L pokemon clear ──
  _pokeget_clear() { clear; pokeget random --hide-name; zle reset-prompt; }
  zle -N _pokeget_clear
  bindkey '^L' _pokeget_clear

  # ── history-aux (sqlite + json) ──
  if (( $+commands[sqlite3] && $+commands[jq] )); then
    zmodload zsh/datetime 2>/dev/null
    export HISTDBFILE=$XDG_DATA_HOME/zsh/zsh_history.db
    export HISTJSFILE=$XDG_DATA_HOME/zsh/zsh_history.json
    typeset -gA _history_aux_state
    _history_aux_state[loaded]=1
    _history_aux_state[session]="${EPOCHREALTIME}-${RANDOM}-${RANDOM}-${TTY##*/}"
    _history_aux_sqlite_init() { emulate -L zsh; setopt local_options; local db="$1"; mkdir -p "${db:h}" || return 1; sqlite3 "$db" "PRAGMA journal_mode=WAL;" >/dev/null 2>&1; sqlite3 "$db" <<'SQL'
CREATE TABLE IF NOT EXISTS zsh_history (id INTEGER PRIMARY KEY, sid TEXT, cwd TEXT, cmd TEXT, ret INTEGER, pipestatus TEXT, start_ts REAL, end_ts REAL);
CREATE INDEX IF NOT EXISTS idx_zsh_history_start_ts ON zsh_history(start_ts DESC);
CREATE INDEX IF NOT EXISTS idx_zsh_history_cmd ON zsh_history(cmd);
SQL
    }
    _history_aux_json_init() { local f="$1"; mkdir -p "${f:h}" || return 1; [[ -f "$f" ]] || touch "$f"; }
    _history_aux_preexec() { emulate -L zsh; setopt local_options extended_glob; local cmd="$1"; [[ -z "$cmd" || "$cmd[1]" == ' ' ]] && return 0; [[ "$options[hist_reduce_blanks]" == on ]] && cmd="${${${cmd//[[:blank:]][[:blank:]]##/ }##[[:blank:]]##}%%[[:blank:]]##}"; _history_aux_state[cmd]="$cmd"; _history_aux_state[start_ts]="$EPOCHREALTIME"; }
    _history_aux_precmd() { local -a _ps=("${pipestatus[@]}"); emulate -L zsh; setopt local_options; [[ -z "${_history_aux_state[cmd]:-}" ]] && return 0; local cmd="${_history_aux_state[cmd]}"; if [[ ( "$options[hist_ignore_dups]" == on || "$options[hist_ignore_all_dups]" == on ) && "$cmd" == "${_history_aux_state[last_cmd]:-}" ]]; then unset '_history_aux_state[cmd]' '_history_aux_state[start_ts]'; return 0; fi; local end_ts="$EPOCHREALTIME" start_ts="${_history_aux_state[start_ts]:-0}" cwd="$PWD" sid="${_history_aux_state[session]}" ret="${_ps[-1]}" my_pipestatus="${(j:,:)_ps}"; if [[ "${_history_aux_state[sqlite_init]:-}" != "$HISTDBFILE" ]]; then _history_aux_sqlite_init "$HISTDBFILE" && _history_aux_state[sqlite_init]="$HISTDBFILE"; fi; [[ "${_history_aux_state[sqlite_init]}" == "$HISTDBFILE" ]] && _history_aux_sqlite_insert "$HISTDBFILE" "$sid" "$cwd" "$cmd" "$ret" "$my_pipestatus" "$start_ts" "$end_ts" &|; if [[ "${_history_aux_state[json_init]:-}" != "$HISTJSFILE" ]]; then _history_aux_json_init "$HISTJSFILE" && _history_aux_state[json_init]="$HISTJSFILE"; fi; [[ "${_history_aux_state[json_init]}" == "$HISTJSFILE" ]] && _history_aux_json_insert "$HISTJSFILE" "$sid" "$cwd" "$cmd" "$ret" "$my_pipestatus" "$start_ts" "$end_ts" &|; _history_aux_state[last_cmd]="$cmd"; unset '_history_aux_state[cmd]' '_history_aux_state[start_ts]'; }
    _history_aux_sqlite_insert() { emulate -L zsh; setopt local_options; local db="$1" q="'"; shift; local -a vals=("$@"); for i in {1..$#vals}; do vals[i]="'${vals[i]//$q/$q$q}'"; done; sqlite3 "$db" "INSERT INTO zsh_history(sid,cwd,cmd,ret,pipestatus,start_ts,end_ts) VALUES(${(j:,:)vals});" >/dev/null 2>&1; }
    _history_aux_json_insert() { jq -cn --arg sid "$2" --arg cwd "$3" --arg cmd "$4" --argjson ret "$5" --arg pipestatus "$6" --argjson start_ts "$7" --argjson end_ts "$8" '{sid:$sid,cwd:$cwd,cmd:$cmd,ret:$ret,pipestatus:$pipestatus,start_ts:$start_ts,end_ts:$end_ts}' >> "$1"; }
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _history_aux_preexec
    add-zsh-hook precmd _history_aux_precmd
    function histdb { emulate -L zsh; local db="$HISTDBFILE"; [[ -f "$db" ]] || { print "histdb: no database at $db" >&2; return 1; }; local -a o_help o_here o_fail o_success o_session o_limit o_reverse; zparseopts -D -E -- {h,-help}=o_help {d,-here}=o_here {f,-fail}=o_fail {r,-reverse}=o_reverse {s,-success}=o_success {S,-session}=o_session {n,-limit}:=o_limit || { print "usage: histdb [-d] [-f] [-s] [-S] [-r] [-n N] [pattern]" >&2; return 1; }; (( $#o_help )) && { print "usage: histdb [-d] [-f] [-s] [-S] [-r] [-n N] [pattern]"; return 0; }; local limit=${o_limit[-1]:-50} pattern=${1:-''} order=ASC; (( $#o_reverse )) && order=DESC; local -a where q="'"; (( $#o_here )) && where+=("cwd = '${PWD//$q/$q$q}'"); (( $#o_session )) && where+=("sid = '${_history_aux_state[session]//$q/$q$q}'"); (( $#o_fail )) && where+=("ret != 0"); (( $#o_success )) && where+=("ret = 0"); [[ -n $pattern ]] && where+=("cmd LIKE '%${pattern//$q/$q$q}%'"); local sql="SELECT datetime(start_ts, 'unixepoch', 'localtime') AS time, printf('%.2f', end_ts - start_ts) AS secs, ret, replace(cwd, '$HOME', '~') AS dir, cmd FROM zsh_history"; (( $#where )) && sql+=" WHERE ${(j: AND :)where}"; sql+=" ORDER BY start_ts $order LIMIT $limit;"; sqlite3 -column -header "$db" "$sql"; }
  fi

  # ── Key bindings that depend on deferred widgets ──
  bindkey '^[OH' beginning-of-line
  bindkey '^[OF' end-of-line
  bindkey '^[[H' beginning-of-line
  bindkey '^[[F' end-of-line
  bindkey '^[[1~' beginning-of-line
  bindkey '^[[4~' end-of-line
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _zush_deferred

# ── Directory backrefs ────────────────────────────────────────────
typeset -g _dotdot=".."
for _index in {1..9}; do
  alias "$_index"="cd -${_index}"
  alias -g "..${_index}"="${_dotdot}"
  _dotdot+="/.."
done
unset _dotdot _index

# ── Powerlevel10k prompt ─────────────────────────────────────────
source $ZDOTDIR/.p10k.zsh
(( ! ${+functions[p10k]} )) || p10k finalize

# ── Never start in root ─────────────────────────────────────────
[[ "$PWD" != "/" ]] || cd

true
