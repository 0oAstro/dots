# Every bash reads this: interactive and login via ~/.bashrc, `bash -c` via
# $BASH_ENV. zsh's .zshenv is the source of truth: its exported result is cached
# as bash and rebuilt when a source file is newer, so the warm path runs no zsh.

export BASHDOTDIR=${BASHDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/bash}
# Non-interactive bash reads only $BASH_ENV; export it so every bash descendant
# gets this file, the way every zsh gets .zshenv.
export BASH_ENV=$BASHDOTDIR/env.bash

_zdots_zshenv_cache=${XDG_CACHE_HOME:-$HOME/.cache}/bash/zshenv.bash

_zdots_zshenv_build() {
  local zdotdir=${ZDOTDIR:-$HOME/.config/zsh} cache=$_zdots_zshenv_cache tmp f
  local -a sources=("$HOME/.zshenv" "$zdotdir/.zshenv" "$zdotdir/lib/path.zsh" "$HOME/.cargo/env")
  command -v zsh >/dev/null || return 1

  # `export X=${X:-default}` in zsh means a caller's value wins; keep that.
  # Top-level `unset NAME` lines have no effect in a clean environment, so
  # carry them over explicitly.
  local defaults unsets
  defaults=$(command grep -ohE 'export [A-Za-z_][A-Za-z0-9_]*=\$\{?[A-Za-z_][A-Za-z0-9_]*:-' -- "${sources[@]}" 2>/dev/null |
    command sed -E 's/^export ([A-Za-z0-9_]+)=\$\{?([A-Za-z0-9_]+):-$/\1 \2/' | command awk '$1 == $2 {print $1}')
  unsets=$(command grep -hE '^[[:space:]]*unset [A-Z]' -- "${sources[@]}" 2>/dev/null |
    command grep -oE '\b[A-Z][A-Z0-9_]*\b' | command grep -vx unset)

  command mkdir -p -- "${cache%/*}" || return 1
  tmp=$(command mktemp "$cache.XXXXXX") || return 1
  # Clean environment: the cache must not capture whatever this caller had.
  if command env -i HOME="$HOME" USER="${USER:-}" LOGNAME="${LOGNAME:-${USER:-}}" \
    PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    ZDOTS_DEFAULTS="$defaults" ZDOTS_UNSETS="$unsets" \
    zsh -fc '
        typeset -A before
        local k
        for k in ${(k)parameters[(R)*export*]}; do before[$k]=${(P)k}; done
        local -a base_path=($path)
        source ~/.zshenv || exit 1
        typeset -A defaults
        for k in ${=ZDOTS_DEFAULTS}; do defaults[$k]=1; done
        print -r -- "# generated from .zshenv by ~/.config/bash/env.bash; do not edit"
        for k in ${(ko)parameters[(R)*export*]}; do
          [[ $k == (PATH|SHLVL|PWD|OLDPWD|_|ZDOTS_DEFAULTS|ZDOTS_UNSETS) ]] && continue
          (( ${+before[$k]} )) && [[ $before[$k] == ${(P)k} ]] && continue
          (( ${+before[$k]} )) || [[ -n ${(P)k} ]] || continue
          if (( ${+defaults[$k]} )); then
            print -r -- "export $k=\${$k:-${(qq)${(P)k}}}"
          else
            print -r -- "export $k=${(qq)${(P)k}}"
          fi
        done
        for k in ${(k)before}; do (( ${+parameters[$k]} )) || print -r -- "unset $k"; done
        for k in ${=ZDOTS_UNSETS}; do print -r -- "unset $k"; done
        # PATH entries .zshenv added, in order; lib/path.bash applies them.
        local -a added=(${path:|base_path})
        print -r -- "_zdots_path_dirs=(${(j: :)${(@qq)added}})"
      ' >"$tmp" && command bash -n "$tmp"; then
    command mv -f -- "$tmp" "$cache"
  else
    command rm -f -- "$tmp"
    return 1
  fi
}

_zdots_zshenv_stale() {
  local zdotdir=${ZDOTDIR:-$HOME/.config/zsh} f
  [[ -r $_zdots_zshenv_cache ]] || return 0
  for f in "$HOME/.zshenv" "$zdotdir/.zshenv" "$zdotdir/lib/path.zsh" \
    "$HOME/.cargo/env" "$BASHDOTDIR/env.bash"; do
    [[ $f -nt $_zdots_zshenv_cache ]] && return 0
  done
  return 1
}

_zdots_path_dirs=()
_zdots_zshenv_stale && _zdots_zshenv_build
[[ -r $_zdots_zshenv_cache ]] && source "$_zdots_zshenv_cache"
unset -f _zdots_zshenv_build _zdots_zshenv_stale
unset _zdots_zshenv_cache

source "$BASHDOTDIR/lib/path.bash"
source "$BASHDOTDIR/lib/secrets.bash"
