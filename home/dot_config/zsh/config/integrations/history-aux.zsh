# Optional sqlite/json history mirror. Enable with ZDOTS_HISTORY_AUX=1.

[[ -n ${ZDOTS_HISTORY_AUX:-} ]] || return

zmodload zsh/datetime
export HISTDBFILE=$XDG_DATA_HOME/zsh/zsh_history.db
export HISTJSFILE=$XDG_DATA_HOME/zsh/zsh_history.json
typeset -gA _history_aux_state
_history_aux_state[loaded]=1
_history_aux_state[session]="${EPOCHREALTIME}-${RANDOM}-${RANDOM}-${TTY##*/}"

_history_aux_sqlite_init() {
  emulate -L zsh
  setopt local_options
  local db=$1
  mkdir -p "${db:h}"
  sqlite3 "$db" "PRAGMA journal_mode=WAL;" >/dev/null
  sqlite3 "$db" <<'SQL'
CREATE TABLE IF NOT EXISTS zsh_history (
id INTEGER PRIMARY KEY, sid TEXT, cwd TEXT, cmd TEXT,
ret INTEGER, pipestatus TEXT, start_ts REAL, end_ts REAL
);
CREATE INDEX IF NOT EXISTS idx_zsh_history_start_ts ON zsh_history(start_ts DESC);
CREATE INDEX IF NOT EXISTS idx_zsh_history_cmd ON zsh_history(cmd);
SQL
}

_history_aux_json_init() {
  local file=$1
  mkdir -p "${file:h}"
  [[ -f $file ]] || touch "$file"
}

_history_aux_preexec() {
  emulate -L zsh
  setopt local_options extended_glob
  local cmd=$1
  [[ -z $cmd || $cmd[1] == ' ' ]] && return 0
  [[ $options[hist_reduce_blanks] == on ]] && cmd="${${${cmd//[[:blank:]][[:blank:]]##/ }##[[:blank:]]##}%%[[:blank:]]##}"
  _history_aux_state[cmd]=$cmd
  _history_aux_state[start_ts]=$EPOCHREALTIME
}

_history_aux_precmd() {
  local -a ps=("${pipestatus[@]}")
  emulate -L zsh
  setopt local_options
  [[ -z ${_history_aux_state[cmd]:-} ]] && return 0

  local cmd=${_history_aux_state[cmd]}
  if [[ ( $options[hist_ignore_dups] == on || $options[hist_ignore_all_dups] == on ) && $cmd == ${_history_aux_state[last_cmd]:-} ]]; then
    unset '_history_aux_state[cmd]' '_history_aux_state[start_ts]'
    return 0
  fi

  local end_ts=$EPOCHREALTIME start_ts=${_history_aux_state[start_ts]:-0}
  local cwd=$PWD sid=${_history_aux_state[session]}
  local ret=${ps[-1]} my_pipestatus=${(j:,:)ps}

  if [[ ${_history_aux_state[sqlite_init]:-} != $HISTDBFILE ]]; then
    _history_aux_sqlite_init "$HISTDBFILE" && _history_aux_state[sqlite_init]=$HISTDBFILE
  fi
  _history_aux_sqlite_insert "$HISTDBFILE" "$sid" "$cwd" "$cmd" "$ret" "$my_pipestatus" "$start_ts" "$end_ts" &|

  if [[ ${_history_aux_state[json_init]:-} != $HISTJSFILE ]]; then
    _history_aux_json_init "$HISTJSFILE" && _history_aux_state[json_init]=$HISTJSFILE
  fi
  _history_aux_json_insert "$HISTJSFILE" "$sid" "$cwd" "$cmd" "$ret" "$my_pipestatus" "$start_ts" "$end_ts" &|

  _history_aux_state[last_cmd]=$cmd
  unset '_history_aux_state[cmd]' '_history_aux_state[start_ts]'
}

_history_aux_sqlite_insert() {
  emulate -L zsh
  setopt local_options
  local db=$1 q="'"
  shift
  local -a vals=("$@")
  local i
  for i in {1..$#vals}; do vals[i]="'${vals[i]//$q/$q$q}'"; done
  sqlite3 "$db" "INSERT INTO zsh_history(sid,cwd,cmd,ret,pipestatus,start_ts,end_ts) VALUES(${(j:,:)vals});" >/dev/null
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

histdb() {
  emulate -L zsh
  local db=$HISTDBFILE
  [[ -f $db ]] || { print "histdb: no database at $db" >&2; return 1; }
  local -a o_help o_here o_fail o_success o_session o_limit o_reverse
  zparseopts -D -E -- \
    {h,-help}=o_help {d,-here}=o_here {f,-fail}=o_fail \
    {r,-reverse}=o_reverse {s,-success}=o_success \
    {S,-session}=o_session {n,-limit}:=o_limit \
    || { print "usage: histdb [-d] [-f] [-s] [-S] [-r] [-n N] [pattern]" >&2; return 1; }
  (( $#o_help )) && { print "usage: histdb [-d] [-f] [-s] [-S] [-r] [-n N] [pattern]"; return 0; }

  local limit=${o_limit[-1]:-50} pattern=${1:-''} order=ASC
  (( $#o_reverse )) && order=DESC
  local -a where
  local q="'"
  (( $#o_here )) && where+=("cwd = '${PWD//$q/$q$q}'")
  (( $#o_session )) && where+=("sid = '${_history_aux_state[session]//$q/$q$q}'")
  (( $#o_fail )) && where+=("ret != 0")
  (( $#o_success )) && where+=("ret = 0")
  [[ -n $pattern ]] && where+=("cmd LIKE '%${pattern//$q/$q$q}%'")

  local sql="SELECT datetime(start_ts, 'unixepoch', 'localtime') AS time,
         printf('%.2f', end_ts - start_ts) AS secs, ret,
         replace(cwd, '$HOME', '~') AS dir, cmd FROM zsh_history"
  (( $#where )) && sql+=" WHERE ${(j: AND :)where}"
  sql+=" ORDER BY start_ts $order LIMIT $limit;"
  sqlite3 -column -header "$db" "$sql"
}
