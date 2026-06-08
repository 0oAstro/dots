#!/bin/zsh
#
# 09-z4h-integrations.zsh — zsh4humans-inspired terminal, tmux, ssh, fzf UX
#

# ── Terminfo / truecolor normalization ───────────────────────────
zmodload zsh/terminfo 2>/dev/null
# Keep TERMINFO as a single-directory override only when the user explicitly
# supplied it. TERMINFO_DIRS from .zshenv is the portable search path.
[[ ${terminfo[Tc]:-} == yes && -z ${COLORTERM:-} ]] && export COLORTERM=truecolor

zterminfo-install() {
  emulate -L zsh; setopt pipefail no_aliases
  local url=${1:-https://github.com/romkatv/terminfo/archive/v1.4.0.tar.gz}
  local tmp=${TMPDIR:-/tmp}/zdots-terminfo.$$
  command mkdir -p "$tmp" "$HOME/.terminfo" || return
  if (( $+commands[curl] )); then
    command curl -fsSL "$url" | command tar -xz -C "$tmp" || return
  elif (( $+commands[wget] )); then
    command wget -O- "$url" | command tar -xz -C "$tmp" || return
  else
    print -ru2 'zterminfo-install: need curl or wget'; return 1
  fi
  local d=($tmp/terminfo-*(N-/))
  [[ -d ${d[1]:-} ]] || return 1
  command cp -R ${d[1]}/* "$HOME/.terminfo/" 2>/dev/null || return
  command rm -rf "$tmp"
  print '✓ installed terminfo into ~/.terminfo'
}

ztic() {
  emulate -L zsh; setopt pipefail no_aliases
  local host=$1 term=${2:-${TERM:-xterm-256color}}
  [[ -n $host ]] || { print -ru2 'usage: ztic <host> [term]'; return 2; }
  command infocmp "$term" 2>/dev/null | command ssh "$host" 'mkdir -p ~/.terminfo && tic -x -' && \
    print "✓ installed terminfo $term on $host"
}

# ── local tmux launcher ──────────────────────────────────────────
ztmux() {
  emulate -L zsh
  local session=${1:-main} term=screen-256color
  (( $+commands[tmux] )) || { print -ru2 'ztmux: tmux not found'; return 127; }
  command infocmp tmux-256color >/dev/null 2>&1 && term=tmux-256color
  TERM=$term exec tmux -u new-session -A -s "$session"
}

# ── SSH teleportation-lite ───────────────────────────────────────
# zssh copies ZDOTDIR and the antidote plugin cache, installs current terminfo,
# and starts remote zsh with ZDOTDIR/ANTIDOTE_HOME pointing at the teleported copy.
zssh() {
  emulate -L zsh; setopt pipefail no_aliases extended_glob
  local mode=shell session=main term host remote_cmd
  zstyle -s ':zdots:ssh:*' term term || term=${TERM:-xterm-256color}

  while (( $# )); do
    case $1 in
      --tmux) mode=tmux; shift ;;
      --tmux=*) mode=tmux; session=${1#--tmux=}; shift ;;
      --term) shift; term=${1:-$term}; shift ;;
      --plain) shift; command ssh "$@"; return $? ;;
      --) shift; break ;;
      -*) print -ru2 "zssh: unsupported option $1"; return 2 ;;
      *) break ;;
    esac
  done

  host=${1:-}; (( $# )) && shift
  [[ -n $host ]] || { print -ru2 'usage: zssh [--tmux[=session]] [--term TERM] <host> [command...]'; return 2; }

  local remote_root='${XDG_CACHE_HOME:-$HOME/.cache}/zdots-teleport'
  local remote_zdot="$remote_root/zsh"
  local remote_antidote='${XDG_CACHE_HOME:-$HOME/.cache}/antidote'

  command infocmp "$term" 2>/dev/null | command ssh "$host" 'mkdir -p ~/.terminfo && tic -x -' >/dev/null 2>&1 || true

  local -a files=(.zshenv .zprofile .zshrc .zstyles .zsh_plugins.txt .zsh_plugins.zsh config functions lib README.md)
  local -a existing=() extra_files
  local f
  for f in $files; do [[ -e $ZDOTDIR/$f ]] && existing+=("$f"); done
  zstyle -a ":zdots:ssh:$host" send-extra-files extra_files || extra_files=()
  for f in $extra_files; do [[ -e ${~f} ]] && existing+=("${~f}"); done
  (( $#existing )) || { print -ru2 "zssh: no payload files under $ZDOTDIR"; return 1; }

  command tar --exclude='.git' --exclude='*.zwc' --exclude='.DS_Store' -czf - -C "$ZDOTDIR" "$existing[@]" | \
    command ssh "$host" "set -e; umask 077; mkdir -p $remote_zdot; tar -xzf - -C $remote_zdot" || return

  if [[ -d ${ANTIDOTE_HOME:-} ]]; then
    command tar --exclude='.git' --exclude='*.zwc' --exclude='.DS_Store' -czf - -C "$ANTIDOTE_HOME" . | \
      command ssh "$host" "set -e; umask 077; mkdir -p $remote_antidote; tar -xzf - -C $remote_antidote" || return
  fi

  if (( $# )); then
    remote_cmd="exec zsh -lic ${(q)${(j: :)${(q)@}}}"
  elif [[ $mode == tmux ]]; then
    remote_cmd="exec tmux -u new-session -A -s ${(q)session} 'env ZDOTDIR=$remote_zdot ANTIDOTE_HOME=$remote_antidote TERM=${(q)term} zsh -li'"
  else
    remote_cmd='exec zsh -li'
  fi

  command ssh -tt "$host" \
    "export ZDOTDIR=$remote_zdot ANTIDOTE_HOME=$remote_antidote TERM=${(q)term} ZDOTS_TELEPORTED=1; cd \$HOME; $remote_cmd"
}

# ── fzf directory picker ────────────────────────────────────────
# Tab completion is handled by compsys-backed Aloxaf/fzf-tab so command-specific
# completions like `brew <TAB>` stay correct and Starship redraw remains intact.
_zdots_fzf_cd_down() {
  setopt local_options no_aliases pipefail
  (( $+commands[fzf] )) || return
  local dir
  if (( $+commands[fd] )); then
    dir=$(fd --type d --hidden --exclude .git --color=never . | sed 's#^./##' | fzf --height ${FZF_TMUX_HEIGHT:-40%} --reverse --scheme=path)
  else
    dir=$(find . -path ./.git -prune -o -type d -print | sed 's#^./##; /^\.$/d' | fzf --height ${FZF_TMUX_HEIGHT:-40%} --reverse --scheme=path)
  fi
  [[ -n $dir ]] || return
  BUFFER="cd ${(q)dir}"; zle accept-line
}
zle -N _zdots_fzf_cd_down
bindkey -M emacs '^[c' _zdots_fzf_cd_down
