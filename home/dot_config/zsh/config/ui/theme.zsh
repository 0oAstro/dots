# Fast, centralized shell theme selection.
#
# Changing either name is enough to switch themes. A matching TOML file in
# config/themes/patina/ wins; otherwise the name is passed to zsh-patina as a
# built-in theme. ZDOTS_APPEARANCE=light|dark is an explicit override.
typeset -g ZDOTS_THEME_LIGHT=${ZDOTS_THEME_LIGHT:-kanagawa-lotus}
typeset -g ZDOTS_THEME_DARK=${ZDOTS_THEME_DARK:-kanagawa-dragon}
typeset -g ZDOTS_APPEARANCE=${ZDOTS_APPEARANCE:-}

_zdots_resolve_appearance() {
  emulate -L zsh

  if [[ $ZDOTS_APPEARANCE != light && $ZDOTS_APPEARANCE != dark ]]; then
    ZDOTS_APPEARANCE=dark

    # macOS does not export its appearance to shells, and Ghostty does not
    # expose which half of a dark:...,light:... theme is active. Cache the
    # preference and use only zsh builtins on the normal startup path. plutil
    # runs once initially and again only when the preferences plist changes.
    if [[ $OSTYPE == darwin* ]]; then
      local plist=$HOME/Library/Preferences/.GlobalPreferences.plist
      local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/macos-appearance
      local cached

      if [[ -r $cache && ( ! -e $plist || $cache -nt $plist ) ]]; then
        IFS= read -r cached < $cache
        [[ $cached == light || $cached == dark ]] && ZDOTS_APPEARANCE=$cached
      else
        if [[ $(command /usr/bin/plutil -extract AppleInterfaceStyle raw -o - $plist 2>/dev/null) == Dark ]]; then
          ZDOTS_APPEARANCE=dark
        else
          ZDOTS_APPEARANCE=light
        fi
        print -r -- $ZDOTS_APPEARANCE >| $cache
      fi
    fi
  fi

  local name
  if [[ $ZDOTS_APPEARANCE == light ]]; then
    name=$ZDOTS_THEME_LIGHT
  else
    name=$ZDOTS_THEME_DARK
  fi

  local file=$ZDOTDIR/config/themes/patina/$name.toml
  if [[ -r $file ]]; then
    typeset -gx ZSH_PATINA_THEME=file:$file
    typeset -g ZDOTS_THEME_FILE=$file
  else
    typeset -gx ZSH_PATINA_THEME=$name
    typeset -g ZDOTS_THEME_FILE=
  fi
  # zsh-patina does not expand arbitrary environment variables inside TOML.
  # Materialize its tiny config from a tracked template only when the selected
  # name changes; the steady-state path is builtin reads and comparisons.
  local template=$ZDOTDIR/config/plugins/zsh-patina.toml.in
  local config=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zsh-patina.toml
  local selection=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/patina-selection
  local previous content
  [[ -r $selection ]] && IFS= read -r previous < $selection
  if [[ $previous != $ZSH_PATINA_THEME || ! -r $config || $template -nt $config ]]; then
    content=$(< $template)
    content=${content//@theme@/$ZSH_PATINA_THEME}
    print -r -- $content >| $config
    print -r -- $ZSH_PATINA_THEME >| $selection
  fi

  typeset -gx ZSH_PATINA_CONFIG_PATH=$config
  typeset -g ZDOTS_THEME=$name
}

_zdots_resolve_appearance
unset -f _zdots_resolve_appearance
