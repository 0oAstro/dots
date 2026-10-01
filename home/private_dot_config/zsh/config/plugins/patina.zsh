# Skip the leftover mise shim for this Cargo-installed tool.
_patina_bin=$CARGO_HOME/bin/zsh-patina
[[ -x $_patina_bin ]] || _patina_bin=${commands[zsh-patina]:-}
if [[ -n $_patina_bin ]]; then
  # Restart only after edits to the static config, not on every shell startup.
  if [[ $ZSH_PATINA_CONFIG_PATH -nt $XDG_CACHE_HOME/zsh/patina-selection ]]; then
    "$_patina_bin" restart >/dev/null 2>&1 &&
      print -r -- "$ZSH_PATINA_THEME" >| "$XDG_CACHE_HOME/zsh/patina-selection"
  fi
  eval "$("$_patina_bin" activate)"
fi
unset _patina_bin
