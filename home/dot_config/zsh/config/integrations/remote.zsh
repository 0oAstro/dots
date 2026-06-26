# Remote shell helpers.

spa() {
  local host="${USER}@spa" session="main"
  if (( $# > 0 )); then
    case "$1" in
      --)
        shift
        (( $# == 0 )) && { echo "usage: spa -- <command>" >&2; return 2; }
        mosh --predict=experimental --predict-overwrite "$host" -- "$@"
        return $?
        ;;
      ssh)
        ssh -tt "$host"
        return $?
        ;;
      *)
        session="$1"
        ;;
    esac
  fi
  mosh --predict=experimental --predict-overwrite "$host" -- tmux new-session -A -s "$session"
}

zssh() {
  emulate -L zsh
  setopt pipefail no_aliases extended_glob

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

  host=${1:-}
  (( $# )) && shift
  [[ -n $host ]] || { print -ru2 'usage: zssh [--tmux[=session]] [--term TERM] <host> [command...]'; return 2; }

  local remote_root='${XDG_CACHE_HOME:-$HOME/.cache}/zdots-teleport'
  local remote_zdot="$remote_root/zsh"
  local remote_antidote='${XDG_CACHE_HOME:-$HOME/.cache}/antidote'

  command infocmp "$term" | command ssh "$host" 'mkdir -p ~/.terminfo && tic -x -' >/dev/null 2>&1

  local -a files=(.zshenv .zprofile .zshrc .zstyles .zsh_plugins.txt .zsh_plugins.zsh config functions lib README.md)
  local -a existing=() extra_files
  local file
  for file in $files; do [[ -e $ZDOTDIR/$file ]] && existing+=("$file"); done
  zstyle -a ":zdots:ssh:$host" send-extra-files extra_files || extra_files=()
  for file in $extra_files; do [[ -e ${~file} ]] && existing+=("${~file}"); done
  (( $#existing )) || { print -ru2 "zssh: no payload files under $ZDOTDIR"; return 1; }

  command tar --exclude='.git' --exclude='*.zwc' --exclude='.DS_Store' -czf - -C "$ZDOTDIR" "$existing[@]" |
    command ssh "$host" "set -e; umask 077; mkdir -p $remote_zdot; tar -xzf - -C $remote_zdot" || return

  command tar --exclude='.git' --exclude='*.zwc' --exclude='.DS_Store' -czf - -C "$ANTIDOTE_HOME" . |
    command ssh "$host" "set -e; umask 077; mkdir -p $remote_antidote; tar -xzf - -C $remote_antidote" || return

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
