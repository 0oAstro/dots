#!/bin/zsh
#
# 07-deferred.zsh — Lazy tool loading + heavy widgets (runs AFTER prompt via precmd)
#

typeset -g _zush_deferred_done=0

_zush_deferred() {
  (( _zush_deferred_done )) && return
  _zush_deferred_done=1

  # ── autopair (deferred init) ──
  (( ${+functions[autopair-init]} )) && autopair-init

  # ── forgit (lazy) ──
  local _forgit=$HOME/Library/Caches/antidote/github.com/wfxr/forgit/forgit.plugin.zsh
  (( ${+commands[fzf]} )) && [[ -r $_forgit ]] && source $_forgit

  # ── Lazy-load brew (on first `brew` call) ──
  local _brew
  for _brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew; do
    if [[ -x $_brew ]]; then
      function brew() {
        unfunction brew
        eval "$($_brew shellenv)"
        brew "$@"
      }
      break
    fi
  done
  unset _brew

  # ── Lazy-load cargo ──
  if [[ -f $CARGO_HOME/env ]]; then
    function cargo()  { unfunction cargo rustc rustup; source $CARGO_HOME/env; cargo "$@"; }
    function rustc()  { unfunction cargo rustc rustup; source $CARGO_HOME/env; rustc "$@"; }
    function rustup() { unfunction cargo rustc rustup; source $CARGO_HOME/env; rustup "$@"; }
  fi

  # ── Lazy-load zoxide ──
  if (( $+commands[zoxide] )); then
    function z()      { unfunction z zoxide zi; eval "$(zoxide init zsh)"; z "$@"; }
    function zoxide() { unfunction z zoxide zi; eval "$(zoxide init zsh)"; zoxide "$@"; }
    function zi()     { unfunction z zoxide zi; eval "$(zoxide init zsh)"; zi "$@"; }
    alias cd=z
  fi

  # ── Clipboard helpers ──
  local _clip_cmd
  if (( $+commands[pbcopy] )); then _clip_cmd=pbcopy
  elif (( $+commands[wl-copy] )); then _clip_cmd='wl-copy'
  elif (( $+commands[xclip] )); then _clip_cmd='xclip -selection clipboard'
  elif (( $+commands[xsel] )); then _clip_cmd='xsel --clipboard --input'
  fi
  copyfile() {
    [[ -n "$_clip_cmd" ]] || { echo "No clipboard tool found."; return 1; }
    [[ -z "$1" ]] && { echo "Usage: copyfile <file>"; return 1; }
    [[ -f "$1" ]] || { echo "Error: '$1' is not a valid file."; return 1; }
    cat "$1" | eval $_clip_cmd
    echo "${(%):-%B$1%b copied to clipboard.}"
  }
  copypath() {
    local file="${1:-.}"
    [[ $file = /* ]] || file="$PWD/$file"
    print -n "${file:a}" | eval $_clip_cmd || return 1
    echo "${(%):-%B${file:a}%b copied to clipboard.}"
  }
  copybuffer() {
    if [[ -n "$_clip_cmd" ]]; then printf "%s" "$BUFFER" | eval $_clip_cmd; else zle -M "No clipboard tool found."; fi
  }
  zle -N copybuffer
  bindkey -M emacs "^O" copybuffer
  bindkey -M viins "^O" copybuffer
  bindkey -M vicmd "^O" copybuffer

  # ── fancy-ctrl-z ──
  function fancy-ctrl-z {
    if [[ $#BUFFER -eq 0 ]]; then BUFFER="fg"; zle accept-line -w
    else zle push-input -w; zle clear-screen -w; fi
  }
  zle -N fancy-ctrl-z
  bindkey '^Z' fancy-ctrl-z

  # ── globalias (Space expands aliases) ──
  typeset -gA _globalias_noexpand
  local -a _words=(ls grep gpg vi e z 0 1 2 3 4 5 6 7 8 9)
  local _w; for _w in "${_words[@]}"; do _globalias_noexpand[$_w]=1; done
  _globalias_expand_word() {
    local word=${${(Az)LBUFFER}[-1]}
    (( $+_globalias_noexpand[$word] )) && return
    (( $+galiases[$word] || ! $+commands[$word] )) && zle _expand_alias
  }
  globalias-space()  { _globalias_expand_word; zle self-insert; }
  globalias-accept() { _globalias_expand_word; zle .accept-line; }
  zle -N globalias-space
  zle -N globalias-accept
  local _gkm
  for _gkm in emacs viins; do
    bindkey -M "$_gkm" ' '  globalias-space
    bindkey -M "$_gkm" '\e ' magic-space
    bindkey -M "$_gkm" '^M' globalias-accept
  done
  bindkey -M isearch ' ' magic-space

  # ── magic-enter (empty Enter → ls / git status) ──
  # (overwrites globalias ^M — globalias only uses Space in practice)
  function magic-enter-cmd {
    local cmd
    zstyle -s ':zsh:plugin:magic-enter' command cmd ||
      cmd="${MAGIC_ENTER_OTHER_COMMAND:-ls}"
    if command git rev-parse --is-inside-work-tree &>/dev/null; then
      zstyle -s ':zsh:plugin:magic-enter' git-command cmd ||
        cmd="${MAGIC_ENTER_GIT_COMMAND:-git status -sb}"
    fi
    echo $cmd
  }
  function magic-enter {
    if [[ -n "$BUFFER" || "$CONTEXT" != start ]]; then
      zle .accept-line; return
    fi
    BUFFER=$(magic-enter-cmd)
    zle .accept-line
  }
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
    _history_aux_sqlite_init() {
      emulate -L zsh; setopt local_options; local db="$1"
      mkdir -p "${db:h}" || return 1
      sqlite3 "$db" "PRAGMA journal_mode=WAL;" >/dev/null 2>&1
      sqlite3 "$db" <<'SQL'
CREATE TABLE IF NOT EXISTS zsh_history (
  id INTEGER PRIMARY KEY, sid TEXT, cwd TEXT, cmd TEXT,
  ret INTEGER, pipestatus TEXT, start_ts REAL, end_ts REAL
);
CREATE INDEX IF NOT EXISTS idx_zsh_history_start_ts ON zsh_history(start_ts DESC);
CREATE INDEX IF NOT EXISTS idx_zsh_history_cmd ON zsh_history(cmd);
SQL
    }
    _history_aux_json_init() { local f="$1"; mkdir -p "${f:h}" || return 1; [[ -f "$f" ]] || touch "$f"; }
    _history_aux_preexec() {
      emulate -L zsh; setopt local_options extended_glob; local cmd="$1"
      [[ -z "$cmd" || "$cmd[1]" == ' ' ]] && return 0
      [[ "$options[hist_reduce_blanks]" == on ]] && cmd="${${${cmd//[[:blank:]][[:blank:]]##/ }##[[:blank:]]##}%%[[:blank:]]##}"
      _history_aux_state[cmd]="$cmd"; _history_aux_state[start_ts]="$EPOCHREALTIME"
    }
    _history_aux_precmd() {
      local -a _ps=("${pipestatus[@]}"); emulate -L zsh; setopt local_options
      [[ -z "${_history_aux_state[cmd]:-}" ]] && return 0
      local cmd="${_history_aux_state[cmd]}"
      if [[ ( "$options[hist_ignore_dups]" == on || "$options[hist_ignore_all_dups]" == on ) \
            && "$cmd" == "${_history_aux_state[last_cmd]:-}" ]]; then
        unset '_history_aux_state[cmd]' '_history_aux_state[start_ts]'; return 0
      fi
      local end_ts="$EPOCHREALTIME" start_ts="${_history_aux_state[start_ts]:-0}"
      local cwd="$PWD" sid="${_history_aux_state[session]}"
      local ret="${_ps[-1]}" my_pipestatus="${(j:,:)_ps}"
      if [[ "${_history_aux_state[sqlite_init]:-}" != "$HISTDBFILE" ]]; then
        _history_aux_sqlite_init "$HISTDBFILE" && _history_aux_state[sqlite_init]="$HISTDBFILE"
      fi
      [[ "${_history_aux_state[sqlite_init]}" == "$HISTDBFILE" ]] && \
        _history_aux_sqlite_insert "$HISTDBFILE" "$sid" "$cwd" "$cmd" "$ret" "$my_pipestatus" "$start_ts" "$end_ts" &|
      if [[ "${_history_aux_state[json_init]:-}" != "$HISTJSFILE" ]]; then
        _history_aux_json_init "$HISTJSFILE" && _history_aux_state[json_init]="$HISTJSFILE"
      fi
      [[ "${_history_aux_state[json_init]}" == "$HISTJSFILE" ]] && \
        _history_aux_json_insert "$HISTJSFILE" "$sid" "$cwd" "$cmd" "$ret" "$my_pipestatus" "$start_ts" "$end_ts" &|
      _history_aux_state[last_cmd]="$cmd"
      unset '_history_aux_state[cmd]' '_history_aux_state[start_ts]'
    }
    _history_aux_sqlite_insert() {
      emulate -L zsh; setopt local_options; local db="$1" q="'"; shift
      local -a vals=("$@")
      for i in {1..$#vals}; do vals[i]="'${vals[i]//$q/$q$q}'"; done
      sqlite3 "$db" \
        "INSERT INTO zsh_history(sid,cwd,cmd,ret,pipestatus,start_ts,end_ts) VALUES(${(j:,:)vals});" \
        >/dev/null 2>&1
    }
    _history_aux_json_insert() {
      jq -cn --arg sid "$2" --arg cwd "$3" --arg cmd "$4" \
        --argjson ret "$5" --arg pipestatus "$6" --argjson start_ts "$7" --argjson end_ts "$8" \
        '{sid:$sid,cwd:$cwd,cmd:$cmd,ret:$ret,pipestatus:$pipestatus,start_ts:$start_ts,end_ts:$end_ts}' \
        >> "$1"
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _history_aux_preexec
    add-zsh-hook precmd _history_aux_precmd
    function histdb {
      emulate -L zsh; local db="$HISTDBFILE"
      [[ -f "$db" ]] || { print "histdb: no database at $db" >&2; return 1; }
      local -a o_help o_here o_fail o_success o_session o_limit o_reverse
      zparseopts -D -E -- \
        {h,-help}=o_help {d,-here}=o_here {f,-fail}=o_fail \
        {r,-reverse}=o_reverse {s,-success}=o_success \
        {S,-session}=o_session {n,-limit}:=o_limit \
        || { print "usage: histdb [-d] [-f] [-s] [-S] [-r] [-n N] [pattern]" >&2; return 1; }
      (( $#o_help )) && { print "usage: histdb [-d] [-f] [-s] [-S] [-r] [-n N] [pattern]"; return 0; }
      local limit=${o_limit[-1]:-50} pattern=${1:-''} order=ASC
      (( $#o_reverse )) && order=DESC
      local -a where q="'"
      (( $#o_here ))    && where+=("cwd = '${PWD//$q/$q$q}'")
      (( $#o_session )) && where+=("sid = '${_history_aux_state[session]//$q/$q$q}'")
      (( $#o_fail ))    && where+=("ret != 0")
      (( $#o_success )) && where+=("ret = 0")
      [[ -n $pattern ]]  && where+=("cmd LIKE '%${pattern//$q/$q$q}%'")
      local sql="SELECT datetime(start_ts, 'unixepoch', 'localtime') AS time,
             printf('%.2f', end_ts - start_ts) AS secs, ret,
             replace(cwd, '$HOME', '~') AS dir, cmd FROM zsh_history"
      (( $#where )) && sql+=" WHERE ${(j: AND :)where}"
      sql+=" ORDER BY start_ts $order LIMIT $limit;"
      sqlite3 -column -header "$db" "$sql"
    }
  fi

  # ── Key bindings (deferred widgets) ──
  bindkey '^[OH' beginning-of-line
  bindkey '^[OF' end-of-line
  bindkey '^[[H' beginning-of-line
  bindkey '^[[F' end-of-line
  bindkey '^[[1~' beginning-of-line
  bindkey '^[[4~' end-of-line
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _zush_deferred
