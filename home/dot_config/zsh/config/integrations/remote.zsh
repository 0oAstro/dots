# Kitty-native aardvark sessions: Kitty owns tabs, kitten ssh provides the
# transparent connection, and zmx keeps each remote shell alive after close.

aardvark() {
  local host="ec2-user@aardvark" session="main" parent="main" remote_dir="" rc
  local existing encoded_session encoded_parent encoded_dir selection canonical_dir existing_window bookmark_name

  if [[ -z "${KITTY_WINDOW_ID:-}" ]]; then
    print -u2 "aardvark: this helper is only supported inside Kitty"
    return 1
  fi

  case "${1:-}" in
    -h|--help)
      print "usage: aardvark [SESSION] [REMOTE_DIRECTORY]"
      print "       aardvark new [PARENT] [REMOTE_DIRECTORY]"
      print "       aardvark pick"
      print "       aardvark bookmark NAME REMOTE_DIRECTORY"
      print "       aardvark bookmarks"
      print "       aardvark {ls|history|kill} [SESSION]"
      print "       aardvark killall"
      return 0
      ;;
    ls|list)
      ssh "$host" zmx ls
      return $?
      ;;
    history)
      session="${2:-main}"
      if [[ -z "$session" || "$session" == *[^A-Za-z0-9_.-]* ]]; then
        print -u2 "aardvark: invalid session name"
        return 2
      fi
      ssh "$host" "zmx history ${(q)session}"
      return $?
      ;;
    kill)
      session="${2:-main}"
      if [[ -z "$session" || "$session" == *[^A-Za-z0-9_.-]* ]]; then
        print -u2 "aardvark: invalid session name"
        return 2
      fi
      ssh "$host" "zmx kill --force ${(q)session}"
      return $?
      ;;
    killall)
      ssh "$host" 'zmx ls --short | xargs -r -n 1 zmx kill --force'
      return $?
      ;;
    bookmarks)
      ssh "$host" 'cat ~/.config/aardvark/projects 2>/dev/null'
      return $?
      ;;
    bookmark)
      bookmark_name="${2:-}"
      remote_dir="${3:-}"
      if [[ -z "$bookmark_name" || "$bookmark_name" == *[^A-Za-z0-9_.-]* || -z "$remote_dir" ]]; then
        print -u2 "usage: aardvark bookmark NAME REMOTE_DIRECTORY"
        return 2
      fi
      canonical_dir=$(ssh "$host" "test -d ${(q)remote_dir} && realpath -e -- ${(q)remote_dir}") || {
        print -u2 "aardvark: remote directory does not exist: $remote_dir"
        return 2
      }
      ssh "$host" "mkdir -p ~/.config/aardvark; printf '%s\\t%s\\n' ${(q)bookmark_name} ${(q)canonical_dir} >> ~/.config/aardvark/projects"
      print "bookmarked $bookmark_name -> $canonical_dir"
      return 0
      ;;
    pick)
      selection=$("$HOME/.config/kitty/aardvark-picker") || return $?
      session="${selection%%$'\t'*}"
      remote_dir="${selection#*$'\t'}"
      if [[ "$remote_dir" == "$selection" ]]; then
        remote_dir=""
      fi

      # Resolve exact user-var values from the complete Kitty tree instead of
      # relying on a regex matcher. This also deliberately excludes the picker.
      existing_window=$(kitten @ ls 2>/dev/null \
        | jq -r --arg session "$session" --arg self "${KITTY_WINDOW_ID:-}" \
          '[.. | objects
            | select(.user_vars?.aardvark_session? == $session)
            | select((.id | tostring) != $self)
            | .id] | .[0] // empty')

      if [[ -n "$existing_window" ]]; then
        kitten @ focus-window --match "id:$existing_window" >/dev/null || return 1
        kitten @ close-window --match "id:${KITTY_WINDOW_ID}" --no-response >/dev/null
        return 0
      fi

      # The picker is an overlay, not a destination. Open unseen projects in a
      # real tab and let aardvark's OSC title name it after the chosen session.
      kitten @ launch --type=tab /bin/zsh -lic \
        "unset KITTY_LISTEN_ON; aardvark ${(q)session} ${(q)remote_dir}" >/dev/null || return 1
      kitten @ close-window --match "id:${KITTY_WINDOW_ID}" --no-response >/dev/null
      return 0
      ;;
    new|--new)
      parent="${2:-main}"
      remote_dir="${3:-}"
      if [[ -z "$parent" || "$parent" == *[^A-Za-z0-9_.-]* ]]; then
        print -u2 "aardvark: invalid parent session name"
        return 2
      fi
      existing=$'\n'"$(ssh "$host" zmx ls --short 2>/dev/null)"$'\n'
      local number=2
      while [[ "$existing" == *$'\n'"${parent}-${number}"$'\n'* ]]; do
        (( number++ ))
      done
      session="${parent}-${number}"
      ;;
    '')
      ;;
    *)
      session="$1"
      remote_dir="${2:-}"
      ;;
  esac

  if [[ -z "$session" || "$session" == *[^A-Za-z0-9_.-]* ]]; then
    print -u2 "aardvark: session names may contain only letters, numbers, ., _, and -"
    return 2
  fi

  # Keep all numbered tabs and panes in one project family.
  if [[ "$1" != "new" && "$1" != "--new" && "$session" =~ '^(.+)-[0-9]+$' ]]; then
    parent="$match[1]"
  elif [[ "$1" != "new" && "$1" != "--new" ]]; then
    parent="$session"
  fi

  # Existing sessions remember their original directory. New project sessions
  # use the selected bookmark/repository directory, falling back to remote HOME.
  if [[ -z "$remote_dir" ]]; then
    remote_dir=$(ssh "$host" zmx ls 2>/dev/null | awk -F '\t' -v target="$session" '
      {
        name=$1; sub(/^.*name=/, "", name)
        if (name == target) {
          dir=$5; sub(/^start_dir=/, "", dir)
          print dir; exit
        }
      }
    ')
  fi
  remote_dir="${remote_dir:-/home/ec2-user}"
  canonical_dir=$(ssh "$host" "test -d ${(q)remote_dir} && realpath -e -- ${(q)remote_dir}") || {
    print -u2 "aardvark: remote directory does not exist: $remote_dir"
    return 2
  }
  remote_dir="$canonical_dir"

  encoded_session=$(printf %s "$session" | base64 | tr -d '\n')
  encoded_parent=$(printf %s "$parent" | base64 | tr -d '\n')
  encoded_dir=$(printf %s "$remote_dir" | base64 | tr -d '\n')

  # Kitty uses these values for project-aware tabs, panes, and termination.
  printf '\e]1337;SetUserVar=aardvark=MQ==\a'
  printf '\e]1337;SetUserVar=aardvark_session=%s\a' "$encoded_session"
  printf '\e]1337;SetUserVar=aardvark_parent=%s\a' "$encoded_parent"
  printf '\e]1337;SetUserVar=aardvark_dir=%s\a' "$encoded_dir"
  printf '\e]2;aardvark:%s\a' "$session"

  # SSH closes its remote PTY with the Kitty pane. zmx drops only that client,
  # while the named shell and any running jobs remain available for reattach.
  kitten ssh -t "$host" "cd -- ${(q)remote_dir} && exec env ZMX_NO_DETACH_KEY=1 zmx attach ${(q)session}"
  rc=$?

  printf '\e]1337;SetUserVar=aardvark\a'
  printf '\e]1337;SetUserVar=aardvark_session\a'
  printf '\e]1337;SetUserVar=aardvark_parent\a'
  printf '\e]1337;SetUserVar=aardvark_dir\a'
  return $rc
}
# zmx session helpers for shells already running on aardvark.

zls() {
  zmx ls
}

zkill() {
  local session="${1:-${ZMX_SESSION:-}}"
  if [[ -z "$session" ]]; then
    print -u2 "usage: zkill SESSION"
    return 2
  fi
  zmx kill --force "$session"
}

zkillall() {
  local -a sessions
  sessions=("${(@f)$(zmx ls --short 2>/dev/null)}")
  if (( ${#sessions} == 0 )); then
    print "zmx: no sessions"
    return 0
  fi

  print "sessions to terminate:"
  printf '  %s\n' "${sessions[@]}"
  read -q "REPLY?kill all zmx sessions? [y/N] " || { print; return 1; }
  print
  zmx kill --force "${sessions[@]}"
}
