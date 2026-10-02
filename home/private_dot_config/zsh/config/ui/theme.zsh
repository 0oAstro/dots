source "$ZDOTDIR/config/themes/shell/ansi.zsh"
typeset -g ZDOTS_THEME=ansi

# bg:-1 lets Ghostty's background show through.
typeset -g +x ZDOTS_FZF_THEME_OPTS="--color=fg:$ZDOTS_COLOR_FG,bg:-1,hl:$ZDOTS_COLOR_MAGENTA,fg+:$ZDOTS_COLOR_FG,bg+:$ZDOTS_COLOR_SELECTION,hl+:$ZDOTS_COLOR_MAGENTA,info:$ZDOTS_COLOR_CYAN,prompt:$ZDOTS_COLOR_BLUE,pointer:$ZDOTS_COLOR_RED,marker:$ZDOTS_COLOR_GREEN,spinner:$ZDOTS_COLOR_YELLOW,header:$ZDOTS_COLOR_CYAN,border:$ZDOTS_COLOR_GREY"
typeset -g +x ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$ZDOTS_COLOR_GREY"
typeset -gx BAT_THEME=ansi

typeset -gx ZSH_PATINA_THEME=$ZDOTS_THEME_PATINA
typeset -gx ZSH_PATINA_CONFIG_PATH=$ZDOTDIR/config/plugins/zsh-patina.toml
