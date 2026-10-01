# shellcheck shell=bash

# get global or local tmux option
get_tmux_option() {
  local -r type="$1"
  local -r name="$2"

  # determine global or local option type
  if [ "$type" == "-g" ]; then keys="-gqv"; else keys="-qv"; fi
  value="$(tmux show-options $keys "$name" 2>/dev/null)"
  echo "$value"
}

# set global or local tmux option
set_tmux_option() {
  local -r type="$1"
  local -r name="$2"
  local -r value="$3"

  if [ "$type" == "-g" ]; then keys="-g"; else keys=""; fi
  tmux set-option $keys "$name" "$value" 2>/dev/null
}

# add to global or local tmux option
add_tmux_option() {
  local -r type="$1"
  local -r name="$2"
  local -r value="$3"

  if [ "$type" == "-g" ]; then keys="-ga"; else keys="-a"; fi
  tmux set-option $keys "$name" "$value" 2>/dev/null
}

set_tmux_env() {
  local -r type="$1"
  local -r name="$2"
  local -r value="$3"

  if [ "$type" == "-g" ]; then keys="-g"; else keys=""; fi
  tmux set-environment $keys "$name" "$value" 2>/dev/null
}
