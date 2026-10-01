# Cache pure integration output by resolved executable and arguments. Mise has
# already activated, so project tool versions resolve without a second lookup.
_zdots_source_generated() {
  emulate -L zsh -o no_aliases
  local tool=$1 binary=${commands[$1]:-}
  shift
  [[ -x $binary ]] || return 0
  [[ $binary != */mise/shims/* ]] || binary=$(command mise which "$tool") || return 1
  binary=${binary:A}
  local dir=$XDG_CACHE_HOME/zsh/integrations${binary:h}
  local cache=$dir/$tool.zsh key="# zdots-v2 $binary ${(j: :)${(q)@}}" saved tmp
  [[ -r $cache ]] && IFS= read -r saved < "$cache"
  if [[ $saved != $key || $binary -nt $cache ]]; then
    command mkdir -p -- "$dir" || return 1
    tmp=$(command mktemp "$cache.XXXXXX") || return 1
    if { print -r -- "$key"; "$binary" "$@"; } >| "$tmp" && command zsh -fn "$tmp"; then
      command mv -f -- "$tmp" "$cache" || return 1
      zcompile "$cache"
    else
      command rm -f -- "$tmp"
      return 1
    fi
  fi
  source "$cache"
}
