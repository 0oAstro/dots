# Apply the PATH entries .zshenv adds ($_zdots_path_dirs, from the cache).
#
# Interactive and login shells get the zsh behaviour: those directories move to
# the front and duplicates collapse to the leftmost entry. Plain `bash -c` and
# scripts (reached through $BASH_ENV) only add missing entries, so a PATH the
# caller deliberately arranged (npm run, mise exec, virtualenvs) keeps its order.

_zdots_path_build() {
  local IFS=: dir out= reorder=$1
  shift
  local -A seen=()
  if [[ $reorder == 1 ]]; then
    for dir in "$@" $PATH; do
      [[ -n $dir && -z ${seen[$dir]+x} ]] || continue
      seen[$dir]=1
      out+=${out:+:}$dir
    done
  else
    for dir in $PATH; do seen[$dir]=1; done
    for dir in "$@"; do
      [[ -n $dir && -z ${seen[$dir]+x} ]] || continue
      seen[$dir]=1
      out+=${out:+:}$dir
    done
    out+=${PATH:+${out:+:}$PATH}
  fi
  PATH=$out
}

if [[ $- == *i* ]] || shopt -q login_shell; then
  _zdots_path_build 1 "${_zdots_path_dirs[@]}"
else
  _zdots_path_build 0 "${_zdots_path_dirs[@]}"
fi
export PATH
unset _zdots_path_dirs
unset -f _zdots_path_build
