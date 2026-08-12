# Fast, centralized shell theme selection.
#
# Changing either name is enough to switch the whole shell palette. Each name
# maps to config/themes/shell/<name>.zsh; that file also selects an official
# zsh-patina theme. ZDOTS_APPEARANCE=light|dark is an explicit override.
typeset -g ZDOTS_THEME_LIGHT=${ZDOTS_THEME_LIGHT:-kanagawa-lotus}
typeset -g ZDOTS_THEME_DARK=${ZDOTS_THEME_DARK:-kanagawa-dragon}
typeset -g ZDOTS_APPEARANCE=${ZDOTS_APPEARANCE:-}

_zdots_resolve_appearance() {
  emulate -L zsh

  local cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
  [[ -d $cache_dir ]] || command mkdir -p -- $cache_dir || return 1

  if [[ $ZDOTS_APPEARANCE != light && $ZDOTS_APPEARANCE != dark ]]; then
    ZDOTS_APPEARANCE=dark

    # macOS does not export its appearance to shells, and Ghostty does not
    # expose which half of a dark:...,light:... theme is active. Cache the
    # preference and use only zsh builtins on the normal startup path. plutil
    # runs once initially and again only when the preferences plist changes.
    if [[ $OSTYPE == darwin* ]]; then
      local plist=$HOME/Library/Preferences/.GlobalPreferences.plist
      local cache=$cache_dir/macos-appearance
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

  local shell_theme=$ZDOTDIR/config/themes/shell/$name.zsh
  if [[ ! -r $shell_theme ]]; then
    print -ru2 -- "zdots: unknown shell theme: $name"
    return 1
  fi
  source $shell_theme

  # Theme files choose an official zsh-patina theme independently from the
  # shell palette. ZDOTS_PATINA_THEME remains available as an explicit override.
  local patina_name=${ZDOTS_PATINA_THEME:-$ZDOTS_THEME_PATINA}
  local patina_file=$ZDOTDIR/config/themes/patina/$patina_name.toml
  if [[ -r $patina_file ]]; then
    typeset -gx ZSH_PATINA_THEME=file:$patina_file
    typeset -g ZDOTS_THEME_FILE=$patina_file
  else
    typeset -gx ZSH_PATINA_THEME=$patina_name
    typeset -g ZDOTS_THEME_FILE=
  fi

  # Keep fzf and autosuggestions on the same palette as the prompt. Transparent
  # backgrounds allow Ghostty's matching Lotus/Dragon terminal theme through.
  typeset -gx ZDOTS_FZF_THEME_OPTS="--color=fg:$ZDOTS_COLOR_FG,bg:-1,hl:$ZDOTS_COLOR_MAGENTA,fg+:$ZDOTS_COLOR_FG,bg+:$ZDOTS_COLOR_SELECTION,hl+:$ZDOTS_COLOR_MAGENTA,info:$ZDOTS_COLOR_CYAN,prompt:$ZDOTS_COLOR_BLUE,pointer:$ZDOTS_COLOR_RED,marker:$ZDOTS_COLOR_GREEN,spinner:$ZDOTS_COLOR_YELLOW,header:$ZDOTS_COLOR_CYAN,border:$ZDOTS_COLOR_GREY"
  typeset -gx ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$ZDOTS_COLOR_GREY"
  typeset -gx BAT_THEME=ansi

  # zsh-patina does not expand arbitrary environment variables inside TOML.
  # Materialize its tiny config from a tracked template only when the selected
  # name changes; the steady-state path is builtin reads and comparisons.
  local template=$ZDOTDIR/config/plugins/zsh-patina.toml.in
  local config=$cache_dir/zsh-patina.toml
  local selection=$cache_dir/patina-selection
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

if ! _zdots_resolve_appearance; then
  unset -f _zdots_resolve_appearance
  return 1
fi
unset -f _zdots_resolve_appearance
