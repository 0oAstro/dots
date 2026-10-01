# The install path, not the shim: skips a mise exec on every startup.
_patina_bin=$XDG_DATA_HOME/mise/installs/cargo-zsh-patina/latest/bin/zsh-patina
# Restart only after edits to the static config, not on every shell startup.
if [[ $ZSH_PATINA_CONFIG_PATH -nt $XDG_CACHE_HOME/zsh/patina-selection ]]; then
  "$_patina_bin" restart >/dev/null 2>&1 &&
    print -r -- "$ZSH_PATINA_THEME" >| "$XDG_CACHE_HOME/zsh/patina-selection"
fi
eval "$("$_patina_bin" activate)"
unset _patina_bin
