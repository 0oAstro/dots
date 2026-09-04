# Aardvark's normal shell helper: mosh provides the resilient connection and
# tmux provides the persistent remote session.

aardvark() {
  local host="ec2-user@aardvark" session="main"
  if (( $# > 0 )); then
    case "$1" in
      --)
        shift
        (( $# == 0 )) && { echo "usage: aardvark -- <command>" >&2; return 2; }
        mosh "$host" -- "$@"
        return $?
        ;;
      ssh)
        mosh "$host"
        return $?
        ;;
      *)
        session="$1"
        ;;
    esac
  fi
  mosh "$host" -- tmux new-session -A -s "$session"
}

alias a='aardvark'

# Herdr already runs on aardvark; keep this as a plain attach shortcut.
ha() {
  if [[ -n ${1:-} ]]; then
    command herdr --remote ec2-user@aardvark --session "$1"
  else
    command herdr --remote ec2-user@aardvark "$@"
  fi
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
