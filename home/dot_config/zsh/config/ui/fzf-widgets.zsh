# UI only: fzf itself owns history parsing, quoting, selection and cd.
(( $+commands[fzf] )) || return 0

# Strip our previous suffix when a nested shell inherits FZF_DEFAULT_OPTS.
if [[ -n ${_ZDOTS_FZF_UI_OPTS:-} ]]; then
  FZF_DEFAULT_OPTS=${FZF_DEFAULT_OPTS//"$_ZDOTS_FZF_UI_OPTS"/}
fi
# Nix layout: roomy reverse picker with the query at the top. Keep Kanagawa
# semantic colors shared with the prompt rather than a separate theme.
export _ZDOTS_FZF_UI_OPTS="--height=80% --layout=reverse --style=minimal --border=rounded --padding=0,1 --no-scrollbar --info=inline-right --separator='' --prompt='~ ' --pointer='› ' --marker='• ' --cycle --bind=ctrl-z:ignore $ZDOTS_FZF_THEME_OPTS --color=prompt:$ZDOTS_COLOR_YELLOW,pointer:$ZDOTS_COLOR_ORANGE,marker:$ZDOTS_COLOR_GREEN,header:$ZDOTS_COLOR_GREEN,info:$ZDOTS_COLOR_CYAN,spinner:$ZDOTS_COLOR_CYAN,fg+:$ZDOTS_COLOR_WHITE,hl:$ZDOTS_COLOR_BLUE,hl+:$ZDOTS_COLOR_MAGENTA,border:$ZDOTS_COLOR_BLUE,label:$ZDOTS_COLOR_MAGENTA,preview-fg:$ZDOTS_COLOR_FG,preview-bg:-1"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+${FZF_DEFAULT_OPTS% } }$_ZDOTS_FZF_UI_OPTS"

if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND=${FZF_DEFAULT_COMMAND:-'fd --type f --hidden --exclude .git --strip-cwd-prefix'}
  export FZF_CTRL_T_COMMAND=${FZF_CTRL_T_COMMAND-$FZF_DEFAULT_COMMAND}
  export FZF_ALT_C_COMMAND=${FZF_ALT_C_COMMAND-'fd --type d --hidden --exclude .git --strip-cwd-prefix'}
fi

local preview="${(q)ZDOTDIR}/bin/fzf-preview"
local preview_layout='right:50%:border-rounded:noinfo:nohidden'
typeset -g FZF_CTRL_T_OPTS="--border-label=' files ' --ghost='find a file' --preview='${preview} {}' --preview-window='$preview_layout'"
typeset -g FZF_ALT_C_OPTS="--border-label=' directories ' --ghost='find a directory' --preview='${preview} {}' --preview-window='$preview_layout'"
typeset -g FZF_CTRL_R_OPTS="--border-label=' history ' --ghost='search commands' --bind=ctrl-u:clear-query,ctrl-k:kill-line,alt-j:clear-query --preview='printf %s {2..}' --preview-window='${preview_layout}:wrap'"
typeset -g FZF_COMPLETION_OPTS="--border-label=' complete ' --tiebreak=chunk --bind=tab:accept"
typeset -g FZF_TAB_COMPLETION_PROMPT='~ '
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' fzf-flags '--border-label= complete ' '--tiebreak=begin' \
  '--bind=tab:accept' '--height=40%' "--preview-window=$preview_layout"
# Restrict previews to file-oriented commands; never evaluate a candidate.
zstyle ':fzf-tab:complete:(cd|z|__zoxide_z|ls|cat|bat|less|nvim|vim|e|cp|mv|rm):*' fzf-preview \
  "$preview \"\$realpath\""

# Alt-R reuses the native directory widget with zoxide as its input source.
_zdots_fzf_dir_history() {
  local FZF_ALT_C_COMMAND='zoxide query -l'
  local FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --border-label=' visited directories ' --ghost='find a visited directory'"
  zle fzf-cd-widget
}
zle -N _zdots_fzf_dir_history
for keymap in emacs viins; do
  bindkey -M "$keymap" '^[r' _zdots_fzf_dir_history
done
unset preview preview_layout keymap
