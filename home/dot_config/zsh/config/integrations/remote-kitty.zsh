# Kitty-native aardvark sessions: Kitty owns tabs, SSH transports the terminal,
# and zmx keeps each remote shell alive after its pane closes. Keep this
# namespace separate from the day-to-day mosh helper in remote.zsh.
# KITTY_AARDVARK_* are optional overrides. Defaults stay local at each use
# site, so merely starting zsh does not export Kitty-specific fallback values.

_kitty_aardvark_valid_name() {
  local name=${1:-}
  [[ -n $name && $name != -* && $name != . && $name != .. && $name != *[^A-Za-z0-9_.-]* ]]
}

_kitty_aardvark_ssh() {
  local host=${KITTY_AARDVARK_HOST:-aardvark}
  ssh -T -o BatchMode=yes -o ConnectTimeout=5 "$host" "$@"
}

_kitty_aardvark_encode() {
  printf %s "$1" | base64 | tr -d '\n'
}

_kitty_aardvark_session_dir() {
  local session=$1
  _kitty_aardvark_ssh zmx ls 2>/dev/null | awk -F '\t' -v target="$session" '
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

_kitty_aardvark_parent() {
  _kitty_aardvark_ssh "zmx get ${(q)1} parent 2>/dev/null"
}

_kitty_aardvark_canonical_dir() {
  local dir=${1:-${KITTY_AARDVARK_HOME:-/home/ec2-user}}
  _kitty_aardvark_ssh "test -d ${(q)dir} && realpath -e -- ${(q)dir}"
}

_kitty_aardvark_controller() {
  local host=${KITTY_AARDVARK_HOST:-aardvark}
  local home=${KITTY_AARDVARK_HOME:-/home/ec2-user}
  local state_dir=${KITTY_AARDVARK_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/aardvark}
  local ctl=${KITTY_AARDVARK_CTL:-$HOME/.config/kitty/aardvark}
  command env \
    KITTY_AARDVARK_HOST="$host" \
    KITTY_AARDVARK_HOME="$home" \
    KITTY_AARDVARK_STATE_DIR="$state_dir" \
    KITTY_AARDVARK_CTL="$ctl" \
    "$ctl" "$@"
}

_kitty_aardvark_picker() {
  local host=${KITTY_AARDVARK_HOST:-aardvark}
  local home=${KITTY_AARDVARK_HOME:-/home/ec2-user}
  local state_dir=${KITTY_AARDVARK_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/aardvark}
  local ctl=${KITTY_AARDVARK_CTL:-$HOME/.config/kitty/aardvark}
  command env \
    KITTY_AARDVARK_HOST="$host" \
    KITTY_AARDVARK_HOME="$home" \
    KITTY_AARDVARK_STATE_DIR="$state_dir" \
    KITTY_AARDVARK_CTL="$ctl" \
    "$HOME/.config/kitty/aardvark-picker"
}

_kitty_aardvark_find_window() {
  local session=$1
  kitten @ ls 2>/dev/null | jq -r --arg session "$session" --arg self "${KITTY_WINDOW_ID:-}" '
    [.. | objects
      | select(.user_vars?.aardvark_session? == $session)
      | select((.id | tostring) != $self)
      | .id] | .[0] // empty'
}

_kitty_aardvark_focus() {
  local id
  id=$(_kitty_aardvark_find_window "$1")
  [[ -n $id ]] || return 1
  kitten @ focus-window --match "id:$id" >/dev/null
}

_kitty_aardvark_set_vars() {
  printf '\e]1337;SetUserVar=aardvark_session=%s\a' "$(_kitty_aardvark_encode "$1")"
  printf '\e]1337;SetUserVar=aardvark_parent=%s\a' "$(_kitty_aardvark_encode "$2")"
  printf '\e]1337;SetUserVar=aardvark_dir=%s\a' "$(_kitty_aardvark_encode "$3")"
}

_kitty_aardvark_clear_vars() {
  printf '\e]1337;SetUserVar=aardvark_session\a'
  printf '\e]1337;SetUserVar=aardvark_parent\a'
  printf '\e]1337;SetUserVar=aardvark_dir\a'
}

_kitty_aardvark_attach() {
  local session=$1 parent=$2 dir=$3
  local rc
  _kitty_aardvark_set_vars "$session" "$parent" "$dir"

  _kitty_aardvark_controller connect "$session" "$dir" "$parent"
  rc=$?
  _kitty_aardvark_clear_vars
  return $rc
}

_kitty_aardvark_resolve() {
  local session=$1 dir=${2:-} parent=${3:-} existing canonical
  local home=${KITTY_AARDVARK_HOME:-/home/ec2-user}

  _kitty_aardvark_valid_name "$session" || {
    print -u2 'aardvark: session names may contain only letters, numbers, ., _, and -'
    return 2
  }

  existing=$(_kitty_aardvark_session_dir "$session")
  if [[ -n $existing ]]; then
    if [[ -z $parent ]]; then
      parent=$(_kitty_aardvark_parent "$session")
      _kitty_aardvark_valid_name "$parent" || parent=$session
    fi
    if [[ -n $dir ]]; then
      canonical=$(_kitty_aardvark_canonical_dir "$dir") || {
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
    _kitty_aardvark_valid_name "$parent" || {
      print -u2 'aardvark: invalid parent session name'
      return 2
    }
    dir=$(_kitty_aardvark_canonical_dir "${dir:-$home}") || {
      print -u2 "aardvark: remote directory does not exist: ${dir:-$home}"
      return 2
    }
  fi

  _kitty_aardvark_attach "$session" "$parent" "$dir"
}

_kitty_aardvark_open() {
  local session=$1 dir=${2:-${KITTY_AARDVARK_HOME:-/home/ec2-user}} parent=${3:-$1}
  if _kitty_aardvark_focus "$session"; then
    kitten @ close-window --match "id:${KITTY_WINDOW_ID}" --no-response >/dev/null
    return
  fi
  _kitty_aardvark_controller launch tab "$session" "$dir" "$parent" >/dev/null || return
  kitten @ close-window --match "id:${KITTY_WINDOW_ID}" --no-response >/dev/null
}

kitty_aardvark() {
  local session=main parent= dir= selection bookmark canonical focused state
  local current_state last_state
  local state_dir=${KITTY_AARDVARK_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/aardvark}
  local -a candidates

  case ${1:-} in
    -h|--help)
      print 'usage: kitty_aardvark [SESSION] [REMOTE_DIRECTORY] [PARENT]'
      print '       kitty_aardvark new [PARENT] [REMOTE_DIRECTORY]'
      print '       kitty_aardvark last [--toggle]'
      print '       kitty_aardvark pick'
      print '       kitty_aardvark bookmark NAME REMOTE_DIRECTORY'
      print '       kitty_aardvark bookmarks'
      print '       kitty_aardvark {ls|history|kill} [SESSION]'
      print '       kitty_aardvark killall'
      return
      ;;
    ls|list)
      _kitty_aardvark_ssh zmx ls
      return
      ;;
    history|kill)
      session=${2:-main}
      _kitty_aardvark_valid_name "$session" || { print -u2 'aardvark: invalid session name'; return 2; }
      if [[ $1 == history ]]; then
        _kitty_aardvark_ssh "zmx history ${(q)session}"
      else
        _kitty_aardvark_ssh "zmx kill --force ${(q)session}"
      fi
      return
      ;;
    killall)
      _kitty_aardvark_ssh 'zmx ls --short | xargs -r zmx kill --force'
      return
      ;;
    bookmarks)
      _kitty_aardvark_ssh 'cat ~/.config/aardvark/projects 2>/dev/null'
      return
      ;;
    bookmark)
      bookmark=${2:-}
      dir=${3:-}
      _kitty_aardvark_valid_name "$bookmark" && [[ -n $dir ]] || {
        print -u2 'usage: aardvark bookmark NAME REMOTE_DIRECTORY'
        return 2
      }
      canonical=$(_kitty_aardvark_canonical_dir "$dir") || {
        print -u2 "aardvark: remote directory does not exist: $dir"
        return 2
      }
      _kitty_aardvark_controller bookmark set "$bookmark" "$canonical" || return
      print "bookmarked $bookmark -> $canonical"
      return
      ;;
    pick)
      selection=$(_kitty_aardvark_picker) || return
      IFS=$'\t' read -r session dir parent <<< "$selection"
      _kitty_aardvark_open "$session" "$dir" "${parent:-$session}"
      return
      ;;
    last)
      [[ -r $state_dir/current ]] && current_state=$(<"$state_dir/current")
      [[ -r $state_dir/last ]] && last_state=$(<"$state_dir/last")
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
        _kitty_aardvark_open "$session" "$dir" "$parent"
        return
      done
      kitty_aardvark pick
      return
      ;;
    new|--new)
      parent=${2:-main}
      dir=${3:-}
      _kitty_aardvark_valid_name "$parent" || { print -u2 'aardvark: invalid parent session name'; return 2; }
      session=$(_kitty_aardvark_ssh zmx ls --short 2>/dev/null | _kitty_aardvark_controller next-name "$parent") || return
      _kitty_aardvark_resolve "$session" "$dir" "$parent"
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

  _kitty_aardvark_focus "$session" || _kitty_aardvark_resolve "$session" "$dir" "$parent"
}
