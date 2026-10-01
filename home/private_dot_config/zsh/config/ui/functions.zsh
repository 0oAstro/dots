bak() {
  local now f
  now=$(date +"%Y%m%d-%H%M%S")
  for f in "$@"; do
    [[ -e $f ]] || { echo "file not found: $f" >&2; continue; }
    cp -R "$f" "$f".$now.bak
  done
}

touchf() {
  [[ -n $1 ]] && [[ ! -f $1 ]] && mkdir -p "$1:h" && touch "$1"
}

up() {
  local parents=${1:-1}
  (( parents > 0 )) || { print -ru2 "up: expecting a numeric parameter"; return 1; }
  local i dotdot=".."
  for ((i = 1; i < parents; i++)); do dotdot+="/.."; done
  cd $dotdot
}

# `function` form: a system profile may already alias `ls`, which would expand
# in an `ls() {` definition.
function ls {
  eza -laH --icons --git --color=auto "$@"
}
