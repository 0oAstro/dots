h() { "${XDG_CONFIG_HOME:-$HOME/.config}/herdr/launch" "$@"; }

# An optional session name selects a separate remote Herdr session.
aardvark() {
  if [[ -n ${1:-} && $1 != -* ]]; then
    local session=$1
    shift
    command herdr --remote aardvark --session "$session" "$@"
  else
    command herdr --remote aardvark "$@"
  fi
}
alias a=aardvark ha=aardvark
