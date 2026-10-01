# Fixed Kanagawa Dragon palette: no OS detection or inherited appearance state.
source "$ZDOTDIR/config/themes/shell/kanagawa-dragon.zsh"
typeset -g ZDOTS_THEME=kanagawa-dragon

# Keep fzf and autosuggestions on the same palette as the prompt. Transparent
# backgrounds allow the terminal's matching Dragon theme through.
typeset -g +x ZDOTS_FZF_THEME_OPTS="--color=fg:$ZDOTS_COLOR_FG,bg:-1,hl:$ZDOTS_COLOR_MAGENTA,fg+:$ZDOTS_COLOR_FG,bg+:$ZDOTS_COLOR_SELECTION,hl+:$ZDOTS_COLOR_MAGENTA,info:$ZDOTS_COLOR_CYAN,prompt:$ZDOTS_COLOR_BLUE,pointer:$ZDOTS_COLOR_RED,marker:$ZDOTS_COLOR_GREEN,spinner:$ZDOTS_COLOR_YELLOW,header:$ZDOTS_COLOR_CYAN,border:$ZDOTS_COLOR_GREY"
typeset -g +x ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$ZDOTS_COLOR_GREY"
typeset -gx BAT_THEME=ansi

# Patina reads a static config directly; no generated template or theme cache.
typeset -gx ZSH_PATINA_THEME=$ZDOTS_THEME_PATINA
typeset -gx ZSH_PATINA_CONFIG_PATH=$ZDOTDIR/config/plugins/zsh-patina.toml
