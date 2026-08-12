# zsh-patina syntax highlighting.
#
# Activation also makes sure the highlighting daemon is running. Do not cache
# its output: sourcing cached shell code installs the ZLE hooks but skips that
# daemon lifecycle step, leaving highlighting silently inactive after it stops.

(( $+commands[zsh-patina] )) || return 0

# The daemon owns the loaded theme. Restart it only when the selected theme
# changes (or its config/custom TOML is edited); ordinary startups stay cheap.
_zdots_patina_marker=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/patina-theme
_zdots_patina_active=
[[ -r $_zdots_patina_marker ]] && IFS= read -r _zdots_patina_active < $_zdots_patina_marker
if [[ $_zdots_patina_active != $ZSH_PATINA_THEME ||
      $ZSH_PATINA_CONFIG_PATH -nt $_zdots_patina_marker ||
      ( -n ${ZDOTS_THEME_FILE:-} && $ZDOTS_THEME_FILE -nt $_zdots_patina_marker ) ]]; then
  if zsh-patina restart >/dev/null 2>&1; then
    print -r -- $ZSH_PATINA_THEME >| $_zdots_patina_marker
  fi
fi
unset _zdots_patina_marker _zdots_patina_active

eval "$(zsh-patina activate)"
