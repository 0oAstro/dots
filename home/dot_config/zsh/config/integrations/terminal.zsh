# Terminal, tmux, and terminfo helpers.

zmodload zsh/terminfo
[[ ${terminfo[Tc]:-} == yes && -z ${COLORTERM:-} ]] && export COLORTERM=truecolor

zterminfo-install() {
  emulate -L zsh
  setopt pipefail no_aliases
  local url=${1:-https://github.com/romkatv/terminfo/archive/v1.4.0.tar.gz}
  local target=${TERMINFO:-${XDG_DATA_HOME:-$HOME/.local/share}/terminfo}
  local tmp
  tmp=$(command mktemp -d "${${TMPDIR:-/tmp}%/}/zdots-terminfo.XXXXXX") || return 1
  {
    command curl -fsSL "$url" | command tar -xz -C "$tmp" || return 1
    local -a trees=($tmp/terminfo-*(N-/))
    (( $#trees == 1 )) || { print -ru2 'zterminfo-install: unexpected archive layout'; return 1; }
    command mkdir -p -- "$target" || return 1
    command cp -R -- $trees[1]/*(D) "$target/" || return 1
    print "installed terminfo into $target"
  } always {
    command rm -rf -- "$tmp"
  }
}

ztic() {
  emulate -L zsh
  setopt pipefail no_aliases
  local host=$1 term=${2:-${TERM:-xterm-256color}}
  [[ -n $host ]] || { print -ru2 'usage: ztic <host> [term]'; return 2; }
  command infocmp "$term" | command ssh "$host" \
    'target=${TERMINFO:-${XDG_DATA_HOME:-$HOME/.local/share}/terminfo}; mkdir -p -- "$target" && TERMINFO=$target tic -x -' \
    || return 1
  print "installed terminfo $term on $host"
}

ztmux() {
  emulate -L zsh
  local session=${1:-main} term=tmux-256color
  TERM=$term exec tmux -u new-session -A -s "$session"
}
