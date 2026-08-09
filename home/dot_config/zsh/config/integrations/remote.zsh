# aardvark Mosh helper.

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
