# aardvark Eternal Terminal helper.

aardvark() {
  local host="ec2-user@aardvark" session="main" remote_command
  if (( $# > 0 )); then
    case "$1" in
      --)
        shift
        (( $# == 0 )) && { echo "usage: aardvark -- <command>" >&2; return 2; }
        remote_command="${(j: :)${(q)@}}"
        et --command "$remote_command" "$host"
        return $?
        ;;
      ssh)
        et "$host"
        return $?
        ;;
      *)
        session="$1"
        ;;
    esac
  fi
  remote_command="tmux new-session -A -s ${(q)session}"
  et --command "$remote_command" "$host"
}
