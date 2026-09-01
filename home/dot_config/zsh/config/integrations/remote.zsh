# Kitty-native aardvark sessions: Kitty owns tabs, SSH transports the terminal,
# and zmx keeps each remote shell alive after its pane closes.

typeset -g AARDVARK_HOST="${AARDVARK_HOST:-aardvark}"
typeset -g AARDVARK_HOME="${AARDVARK_HOME:-/home/ec2-user}"
typeset -g AARDVARK_STATE_DIR="${AARDVARK_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/aardvark}"
typeset -g AARDVARK_CTL="$HOME/.config/kitty/aardvark"

_aardvark_valid_name() {
  local name=${1:-}
  [[ -n $name && $name != -* && $name != . && $name != .. && $name != *[^A-Za-z0-9_.-]* ]]
}

_aardvark_ssh() {
  ssh -T -o BatchMode=yes -o ConnectTimeout=5 "$AARDVARK_HOST" "$@"
}

_aardvark_encode() {
  printf %s "$1" | base64 | tr -d '\n'
}

_aardvark_session_dir() {
  local session=$1
  _aardvark_ssh zmx ls 2>/dev/null | awk -F '\t' -v target="$session" '
    {
      name = dir = ""
      for (i = 1; i <= NF; i++) {
        field = $i
        sub(/^ +/, "", field)
        if (field ~ /^name=/) { name = field; sub(/^name=/, "", name) }
        if (field ~ /^start_dir=/) { dir = field; sub(/^start_dir=/, "", dir) }
      }
      if (name == target) { print dir; exit }
    }'
}

_aardvark_parent() {
  _aardvark_ssh "zmx get ${(q)1} parent 2>/dev/null"
}

_aardvark_canonical_dir() {
  local dir=${1:-$AARDVARK_HOME}
  _aardvark_ssh "test -d ${(q)dir} && realpath -e -- ${(q)dir}"
}

_aardvark_find_window() {
  local session=$1
  kitten @ ls 2>/dev/null | jq -r --arg session "$session" --arg self "${KITTY_WINDOW_ID:-}" '
    [.. | objects
      | select(.user_vars?.aardvark_session? == $session)
      | select((.id | tostring) != $self)
      | .id] | .[0] // empty'
}

_aardvark_focus() {
  local id
  id=$(_aardvark_find_window "$1")
  [[ -n $id ]] || return 1
  kitten @ focus-window --match "id:$id" >/dev/null
}

_aardvark_set_vars() {
  printf '\e]1337;SetUserVar=aardvark_session=%s\a' "$(_aardvark_encode "$1")"
  printf '\e]1337;SetUserVar=aardvark_parent=%s\a' "$(_aardvark_encode "$2")"
  printf '\e]1337;SetUserVar=aardvark_dir=%s\a' "$(_aardvark_encode "$3")"
}

_aardvark_clear_vars() {
  printf '\e]1337;SetUserVar=aardvark_session\a'
  printf '\e]1337;SetUserVar=aardvark_parent\a'
  printf '\e]1337;SetUserVar=aardvark_dir\a'
}

_aardvark_attach() {
  local session=$1 parent=$2 dir=$3 rc
  _aardvark_set_vars "$session" "$parent" "$dir"

  "$AARDVARK_CTL" connect "$session" "$dir" "$parent"
  rc=$?
  _aardvark_clear_vars
  return $rc
}

_aardvark_resolve() {
  local session=$1 dir=${2:-} parent=${3:-} existing canonical

  _aardvark_valid_name "$session" || {
    print -u2 'aardvark: session names may contain only letters, numbers, ., _, and -'
    return 2
  }

  existing=$(_aardvark_session_dir "$session")
  if [[ -n $existing ]]; then
    if [[ -z $parent ]]; then
      parent=$(_aardvark_parent "$session")
      _aardvark_valid_name "$parent" || parent=$session
    fi
    if [[ -n $dir ]]; then
      canonical=$(_aardvark_canonical_dir "$dir") || {
        print -u2 "aardvark: remote directory does not exist: $dir"
        return 2
      }
      if [[ $canonical != $existing ]]; then
        print -u2 "aardvark: '$session' already lives at $existing"
        return 2
      fi
    fi
    dir=$existing
  else
    parent=${parent:-$session}
    _aardvark_valid_name "$parent" || {
      print -u2 'aardvark: invalid parent session name'
      return 2
    }
    dir=$(_aardvark_canonical_dir "${dir:-$AARDVARK_HOME}") || {
      print -u2 "aardvark: remote directory does not exist: ${dir:-$AARDVARK_HOME}"
      return 2
    }
  fi

  _aardvark_attach "$session" "$parent" "$dir"
}

_aardvark_open() {
  local session=$1 dir=${2:-$AARDVARK_HOME} parent=${3:-$1}
  if _aardvark_focus "$session"; then
    kitten @ close-window --match "id:${KITTY_WINDOW_ID}" --no-response >/dev/null
    return
  fi
  "$AARDVARK_CTL" launch tab "$session" "$dir" "$parent" >/dev/null || return
  kitten @ close-window --match "id:${KITTY_WINDOW_ID}" --no-response >/dev/null
}

aardvark() {
  local session=main parent= dir= selection bookmark canonical focused state
  local current_state last_state
  local -a candidates

  [[ $OSTYPE == darwin* && -n ${KITTY_WINDOW_ID:-} ]] || {
    print -u2 'aardvark: this helper is only supported in local Kitty'
    return 1
  }

  case ${1:-} in
    -h|--help)
      print 'usage: aardvark [SESSION] [REMOTE_DIRECTORY] [PARENT]'
      print '       aardvark new [PARENT] [REMOTE_DIRECTORY]'
      print '       aardvark last [--toggle]'
      print '       aardvark pick'
      print '       aardvark bookmark NAME REMOTE_DIRECTORY'
      print '       aardvark bookmarks'
      print '       aardvark {ls|history|kill} [SESSION]'
      print '       aardvark killall'
      return
      ;;
    ls|list)
      _aardvark_ssh zmx ls
      return
      ;;
    history|kill)
      session=${2:-main}
      _aardvark_valid_name "$session" || { print -u2 'aardvark: invalid session name'; return 2; }
      if [[ $1 == history ]]; then
        _aardvark_ssh "zmx history ${(q)session}"
      else
        _aardvark_ssh "zmx kill --force ${(q)session}"
      fi
      return
      ;;
    killall)
      _aardvark_ssh 'zmx ls --short | xargs -r zmx kill --force'
      return
      ;;
    bookmarks)
      _aardvark_ssh 'cat ~/.config/aardvark/projects 2>/dev/null'
      return
      ;;
    bookmark)
      bookmark=${2:-}
      dir=${3:-}
      _aardvark_valid_name "$bookmark" && [[ -n $dir ]] || {
        print -u2 'usage: aardvark bookmark NAME REMOTE_DIRECTORY'
        return 2
      }
      canonical=$(_aardvark_canonical_dir "$dir") || {
        print -u2 "aardvark: remote directory does not exist: $dir"
        return 2
      }
      "$AARDVARK_CTL" bookmark set "$bookmark" "$canonical" || return
      print "bookmarked $bookmark -> $canonical"
      return
      ;;
    pick)
      selection=$("$HOME/.config/kitty/aardvark-picker") || return
      IFS=$'\t' read -r session dir parent <<< "$selection"
      _aardvark_open "$session" "$dir" "${parent:-$session}"
      return
      ;;
    last)
      [[ -r $AARDVARK_STATE_DIR/current ]] && current_state=$(<"$AARDVARK_STATE_DIR/current")
      [[ -r $AARDVARK_STATE_DIR/last ]] && last_state=$(<"$AARDVARK_STATE_DIR/last")
      focused=$(kitten @ ls --match "id:${KITTY_WINDOW_ID}" 2>/dev/null \
        | jq -r '[.. | objects | .user_vars?.aardvark_session? // empty] | .[0] // empty')
      if [[ ${2:-} == --toggle ]]; then
        candidates=("$last_state")
      else
        candidates=("$current_state" "$last_state")
      fi
      for state in "${candidates[@]}"; do
        [[ -n $state ]] || continue
        IFS=$'\t' read -r session dir parent <<< "$state"
        [[ $session != $focused ]] || continue
        _aardvark_open "$session" "$dir" "$parent"
        return
      done
      aardvark pick
      return
      ;;
    new|--new)
      parent=${2:-main}
      dir=${3:-}
      _aardvark_valid_name "$parent" || { print -u2 'aardvark: invalid parent session name'; return 2; }
      session=$(_aardvark_ssh zmx ls --short 2>/dev/null | "$AARDVARK_CTL" next-name "$parent") || return
      _aardvark_resolve "$session" "$dir" "$parent"
      return
      ;;
    '')
      ;;
    *)
      session=$1
      dir=${2:-}
      parent=${3:-}
      ;;
  esac

  _aardvark_focus "$session" || _aardvark_resolve "$session" "$dir" "$parent"
}

# Short zmx commands for shells already running on aardvark.
zls() {
  zmx ls
}

zkill() {
  local session=${1:-${ZMX_SESSION:-}}
  [[ -n $session ]] || { print -u2 'usage: zkill SESSION'; return 2; }
  zmx kill --force "$session"
}

zkillall() {
  local -a sessions
  sessions=("${(@f)$(zmx ls --short 2>/dev/null)}")
  (( ${#sessions} )) || { print 'zmx: no sessions'; return; }
  print 'sessions to terminate:'
  printf '  %s\n' "${sessions[@]}"
  read -q 'REPLY?kill all zmx sessions? [y/N] ' || { print; return 1; }
  print
  zmx kill --force "${sessions[@]}"
}
