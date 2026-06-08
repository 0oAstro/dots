
# ── forgit (lazy) ──
local _forgit=$ANTIDOTE_HOME/github.com/wfxr/forgit/forgit.plugin.zsh
(( ${+commands[fzf]} )) && [[ -r $_forgit ]] && source $_forgit

# ── Homebrew (already set in .zshenv — no lazy-load needed) ───
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

# ═══════════════════════════════════════════════════════════════════
# Enter key behavior — inspired by mattmc3/zdotdir
#
# Two layers, completely separate:
#   1. globalias-accept — Fish-like alias expansion on Space/Enter
#   2. magic-enter      — accept_line_hook, fills empty prompts
#
# ═══════════════════════════════════════════════════════════════════

# ── globalias: Fish-like abbreviation expansion ───────────────────
# Space  → expand the last word if it's an alias, then insert space
# Enter  → expand the last word if it's an alias, then execute
# Alt+Space → insert a literal space without expanding
#
# Skip expansion for words in the noexpand list (common commands
# that happen to be aliased, or dirstack shortcuts).

typeset -gA _globalias_noexpand
() {
  local -a _words
  local _w
  zstyle -a ':zdots:globalias' noexpand '_words' 2>/dev/null \
    || _words=(ls grep gpg vi e z 0 1 2 3 4 5 6 7 8 9)
  for _w in "${_words[@]}"; do
    _globalias_noexpand[$_w]=1
  done
}

_globalias_expand_word() {
  local word=${${(Az)LBUFFER}[-1]}
  (( $+_globalias_noexpand[$word] )) && return
  (( $+galiases[$word] || ! $+commands[$word] )) && zle _expand_alias
}

globalias-space() {
  _globalias_expand_word
  zle self-insert
}
zle -N globalias-space

globalias-accept() {
  # If buffer is empty, fill it with the default command (magic-enter)
  if [[ -z "$BUFFER" && "$CONTEXT" == start ]]; then
    BUFFER=$(magic-enter-cmd)
  else
    _globalias_expand_word
  fi
  zle accept-line
}
zle -N globalias-accept

for _gkm in emacs viins; do
  bindkey -M "$_gkm" ' '   globalias-space
  bindkey -M "$_gkm" '\e ' magic-space
  bindkey -M "$_gkm" '^M'  globalias-accept
done
bindkey -M isearch ' ' magic-space
unset _gkm

# ── magic-enter: empty prompt → ls / git status ──────────────────
# Checks happen inside globalias-accept and accept-line-plain.
# (Same effect as matt's accept_line_hook but works with standard zsh.)
function magic-enter-cmd {
  local cmd
  zstyle -s ':zdots:magic-enter' command cmd || cmd="${MAGIC_ENTER_OTHER_COMMAND:-ls}"
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    zstyle -s ':zdots:magic-enter' git-command cmd || cmd="${MAGIC_ENTER_GIT_COMMAND:-git status -sb}"
  fi
  echo $cmd
}

# ── Alt+Enter: plain execute (no expansion) ──────────────────────
accept-line-plain() {
  # Also handle magic-enter for empty prompts
  if [[ -z "$BUFFER" && "$CONTEXT" == start ]]; then
    BUFFER=$(magic-enter-cmd)
  fi
  zle .accept-line
}
zle -N accept-line-plain
bindkey -M emacs  '^[^M' accept-line-plain
bindkey -M viins  '^[^M' accept-line-plain
bindkey -M isearch '^[^M' accept-line-plain
# ═══════════════════════════════════════════════════════════════════

# ── Right arrow / Ctrl+E: accept full suggestion ──────────────────
accept-full-suggestion() {
  if [[ -n $POSTDISPLAY ]]; then
    BUFFER="$BUFFER$POSTDISPLAY"
    POSTDISPLAY=""
  fi
  zle end-of-line
}
zle -N accept-full-suggestion
bindkey -M emacs '^[[C' accept-full-suggestion
bindkey -M emacs '^[OC' accept-full-suggestion
bindkey -M emacs '^E' accept-full-suggestion

# ── Alt+F / Alt+→: accept one word of suggestion ─────────────────
accept-suggestion-word() {
  if [[ -n $POSTDISPLAY ]]; then
    local rest=$POSTDISPLAY take
    if [[ $rest == [[:space:]]##* ]]; then
      take=${${rest%%[^[:space:]]*}:-$rest}
      rest=${rest#$take}
    fi
    if [[ -n $rest ]]; then
      local wordchars=${WORDCHARS//[[:space:][:alnum:]]}
      if [[ $rest == [[:alnum:]$wordchars]##* ]]; then
        take+=${rest%%[^[:alnum:]$wordchars]*}
      else
        take+=${rest[1]}
      fi
    fi
    [[ -n $take ]] || take=${POSTDISPLAY[1]}
    BUFFER+=$take
    POSTDISPLAY=${POSTDISPLAY#$take}
  fi
  zle end-of-line
}
zle -N accept-suggestion-word
bindkey -M emacs '^[[1;3C' accept-suggestion-word
bindkey -M emacs '^[Oc' accept-suggestion-word
bindkey -M emacs '^[f' accept-suggestion-word

# ── Ctrl+L pokemon clear ──
_pokeget_clear() {
  clear
  (( $+commands[pokeget] )) && [[ -t 1 && $TERM != dumb ]] && pokeget random --hide-name 2>/dev/null
  zle reset-prompt
}
zle -N _pokeget_clear
bindkey '^L' _pokeget_clear

# ── history-aux (sqlite + json, opt-in: export ZDOTS_HISTORY_AUX=1) ──
# Disabled by default: it forks sqlite3+jq on every prompt and dominates command lag.
if [[ -n ${ZDOTS_HISTORY_AUX:-} ]] && (( $+commands[sqlite3] && $+commands[jq] )); then
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
    local -a where
    local q="'"
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

# ── zsh4humans-inspired fzf/history/directory widgets ─────────────
_zfh_fzf_cmd() { (( $+commands[fzf] )) || { zle -M "fzf not found"; return 1; } }

_zfh_accept_autosuggest_full() {
  if (( $+widgets[autosuggest-accept] )) && [[ -n $POSTDISPLAY ]]; then
    zle autosuggest-accept
  else
    zle end-of-line
  fi
}
zle -N _zfh_accept_autosuggest_full

_zfh_accept_autosuggest_word() {
  emulate -L zsh -o extended_glob
  if [[ -n $POSTDISPLAY ]]; then
    local rest=$POSTDISPLAY take
    if [[ $rest == [[:space:]]##* ]]; then
      take=${${rest%%[^[:space:]]*}:-$rest}
      rest=${rest#$take}
    fi
    if [[ -n $rest ]]; then
      local wordchars=${WORDCHARS//[[:space:][:alnum:]]}
      if [[ $rest == [[:alnum:]$wordchars]##* ]]; then
        take+=${rest%%[^[:alnum:]$wordchars]*}
      else
        take+=${rest[1]}
      fi
    fi
    [[ -n $take ]] || take=${POSTDISPLAY[1]}
    BUFFER+=$take
    POSTDISPLAY=${POSTDISPLAY#$take}
    CURSOR=${#BUFFER}
    zle .reset-prompt
  else
    zle _zfh_forward_word
  fi
}
zle -N _zfh_accept_autosuggest_word

_zfh_forward_word() {
  emulate -L zsh -o extended_glob
  local buf w=${WORDCHARS//[[:space:][:alnum:]]}
  repeat ${NUMERIC:-1}; do
    buf=${RBUFFER##[[:space:]]#}
    if (( $#buf < 2 )); then
      buf=
    elif [[ $buf == ?[[:space:]]* ]]; then
      buf[1]=
    elif [[ $buf[1,2] != *[[:alnum:]$w]* ]]; then
      buf=${buf##[^[:space:][:alnum:]$w]#}
    else
      [[ $buf == [[:alnum:]$w]* ]] || buf[1]=
      buf=${buf##[[:alnum:]$w]#}
    fi
    (( CURSOR += $#RBUFFER - $#buf ))
  done
}
zle -N _zfh_forward_word

_zfh_backward_word() {
  emulate -L zsh -o extended_glob
  local buf w=${WORDCHARS//[[:space:][:alnum:]]}
  repeat ${NUMERIC:-1}; do
    buf=${LBUFFER%%[[:space:]]#}
    if (( $#buf < 2 )); then
      buf=
    elif [[ $buf == *[[:space:]]? ]]; then
      buf[-1]=
    elif [[ $buf[-2,-1] != *[[:alnum:]$w]* ]]; then
      buf=${buf%%[^[:space:][:alnum:]$w]#}
    else
      [[ $buf == *[[:alnum:]$w] ]] || buf[-1]=
      buf=${buf%%[[:alnum:]$w]#}
    fi
    (( CURSOR -= $#LBUFFER - $#buf ))
  done
}
zle -N _zfh_backward_word

_zfh_forward_zword() {
  emulate -L zsh
  local word buf
  repeat ${NUMERIC:-1}; do
    buf=$PREBUFFER$BUFFER
    for word in ${(Z:n:)buf} ''; do
      (( $#buf < $#RBUFFER )) && break
      buf=${${buf##[[:space:]]#}:$#word}
    done
    CURSOR=$(($#BUFFER - $#buf))
    (( CURSOR > $#BUFFER )) && CURSOR=$#BUFFER
  done
}
zle -N _zfh_forward_zword

_zfh_backward_zword() {
  emulate -L zsh
  local word buf tail
  repeat ${NUMERIC:-1}; do
    buf=$PREBUFFER$BUFFER
    for word in '' ${(Z:n:)buf}; do
      tail=${${buf:$#word}##[[:space:]]#}
      (( $#tail <= $#RBUFFER )) && break
      buf=$tail
    done
    CURSOR=$(($#buf <= $#BUFFER ? $#BUFFER - $#buf : 0))
  done
}
zle -N _zfh_backward_zword

_zfh_fzf_history() {
  _zfh_fzf_cmd || return
  local selected
  selected=$(fc -rl 1 2>/dev/null | awk '{$1=""; sub(/^ /,""); if (!seen[$0]++) print}' | \
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --height=80% --layout=reverse --border --no-multi --exact --cycle --bind=ctrl-u:clear-query,ctrl-k:kill-line,alt-j:clear-query" \
    fzf --query="$LBUFFER" --preview 'printf %s {}' --preview-window=wrap:3:down:noborder) || return
  BUFFER=$selected
  CURSOR=${#BUFFER}
  zle -R
}
zle -N _zfh_fzf_history

_zfh_fzf_dir_history() {
  _zfh_fzf_cmd || return
  local selected source_cmd
  if (( $+commands[zoxide] )); then
    source_cmd='zoxide query -l 2>/dev/null'
  else
    source_cmd='dirs -lp 2>/dev/null; print -rl -- ${(u)$(fc -rl 1 2>/dev/null | sed -n "s/.*cd \\([^;&|]*\\).*/\\1/p")}'
  fi
  selected=$(eval $source_cmd | awk 'NF && !seen[$0]++' | \
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} --height=80% --layout=reverse --border --no-multi --exact --cycle --bind=tab:down,btab:up,ctrl-u:clear-query" \
    fzf --preview 'eza -la --color=always {} 2>/dev/null || ls -la {} 2>/dev/null' --preview-window=right:50%) || return
  [[ -d $selected ]] || { zle -M "not a directory: $selected"; return 1; }
  cd -- $selected || return
  zle reset-prompt
}
zle -N _zfh_fzf_dir_history

# ── Key bindings ──
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# zsh4humans-style autosuggestion/navigation bindings
bindkey -M emacs '^[[1;5C' _zfh_forward_zword
bindkey -M emacs '^[[D' backward-char
bindkey -M emacs '^[[1;3D' _zfh_backward_word
bindkey -M emacs '^[b' _zfh_backward_word
bindkey -M emacs '^[[1;5D' _zfh_backward_zword
bindkey -M emacs '^R' _zfh_fzf_history
bindkey -M emacs '^[r' _zfh_fzf_dir_history
bindkey -M emacs '^[[3;5~' kill-word
bindkey -M emacs '^[[3;3~' kill-word

# ── Autosuggestions ───────────────────────────────────────────────
ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(
  globalias-accept globalias-space
  accept-full-suggestion accept-suggestion-word
  _zfh_fzf_history _zfh_fzf_dir_history
  accept-line-plain
)

# ── Esc clears autosuggestion (low timeout avoids arrow-key lag) ──
KEYTIMEOUT=1
bindkey -M emacs '^[' autosuggest-clear

# ── Backspace: normal delete char ──
bindkey -M emacs '^?' backward-delete-char
bindkey -M emacs '^H' backward-delete-char
