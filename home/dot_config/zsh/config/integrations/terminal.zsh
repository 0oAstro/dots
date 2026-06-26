# Terminal, tmux, and terminfo helpers.

zmodload zsh/terminfo
[[ ${terminfo[Tc]:-} == yes && -z ${COLORTERM:-} ]] && export COLORTERM=truecolor

zterminfo-install() {
  emulate -L zsh
  setopt pipefail no_aliases
  local url=${1:-https://github.com/romkatv/terminfo/archive/v1.4.0.tar.gz}
  local tmp=${TMPDIR:-/tmp}/zdots-terminfo.$$
  command mkdir -p "$tmp" "$HOME/.terminfo"
  command curl -fsSL "$url" | command tar -xz -C "$tmp"
  local d=($tmp/terminfo-*(N-/))
  command cp -R ${d[1]}/* "$HOME/.terminfo/"
  command rm -rf "$tmp"
  print 'installed terminfo into ~/.terminfo'
}

ztic() {
  emulate -L zsh
  setopt pipefail no_aliases
  local host=$1 term=${2:-${TERM:-xterm-256color}}
  [[ -n $host ]] || { print -ru2 'usage: ztic <host> [term]'; return 2; }
  command infocmp "$term" | command ssh "$host" 'mkdir -p ~/.terminfo && tic -x -'
  print "installed terminfo $term on $host"
}

ztmux() {
  emulate -L zsh
  local session=${1:-main} term=tmux-256color
  TERM=$term exec tmux -u new-session -A -s "$session"
}
