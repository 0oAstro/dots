# One completion init, after the complete fpath is assembled. No presets.
ZSH_COMPDUMP=$XDG_CACHE_HOME/zsh/zcompdump-$HOST-$ZSH_VERSION

() {
  emulate -L zsh -o extended_glob
  local dump=$ZSH_COMPDUMP key="$ZSH_VERSION:${(j.:.)fpath}"
  local saved
  [[ -r $dump.fpath ]] && saved=$(< "$dump.fpath")
  local -a newer=( ${^fpath}(N/e:'[[ $REPLY -nt $dump ]]':) )
  autoload -Uz compinit

  if [[ -s $dump && $saved == $key && -n $dump(#qNmh-24) ]] && (( ! $#newer )); then
    compinit -C -d "$dump"
  else
    # A changed fpath can have the same file count: do not reuse its old map.
    command rm -f -- "$dump" "$dump.zwc"
    compinit -i -d "$dump"
    print -r -- "$key" >| "$dump.fpath"
    [[ -s $dump ]] && zcompile "$dump"
  fi
}

_comp_options+=(globdots)

# Command-specific definitions belong to the provider, not a dotfiles registry.
# It supplies candidates to zsh; the fzf selector only controls their display.
if (( $+commands[carapace] )); then
  # Native zsh completions are already present; avoid recursive bridge shells.
  export CARAPACE_BRIDGES=''
  () {
    local -A native=( "${(@kv)_comps}" )
    # Load completions without Carapace prepending its unused wrapper directory.
    # Keep mise's PATH stable so its first precmd need not activate a second time.
    local -a path=( "$path[@]" )
    _zdots_source_generated carapace _carapace zsh
    # Fill gaps without replacing working native definitions.
    _comps+=( "${(@kv)native}" )
  }
fi

# Prefer native generators where the upstream catalog has one. Loading the
# catalog is builtin-only; generation happens automatically on first Tab.
typeset -gA _zdots_completion_generators _zdots_completion_catalog_versions _zdots_completion_fallbacks
autoload -Uz _zdots_native_completion
() {
  local catalog tool recipe
  local -A info
  zmodload -F zsh/stat b:zstat
  for catalog in ${^fpath}/generators.csv(N); do
    zstat -H info -- "$catalog" || continue
    while IFS=, read -r tool recipe; do
      [[ -n $tool && $tool != Tool && -n $recipe ]] || continue
      _zdots_completion_generators[$tool]=$recipe
      _zdots_completion_catalog_versions[$tool]=$info[mtime]-$info[size]
      if [[ ${_comps[$tool]:-} != _zdots_native_completion ]]; then
        _zdots_completion_fallbacks[$tool]=${_comps[$tool]:-_default}
      fi
      compdef _zdots_native_completion "$tool"
    done < "$catalog"
  done
}
