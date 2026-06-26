# fzf environment and shell key bindings.
#

local preview_file='bat --color=always --style=numbers --line-range=:160 {}'
local preview_dir='eza --all --color=always --tree --level=2 {}'

export FZF_CTRL_T_OPTS="--preview '$preview_file'"
export FZF_ALT_C_OPTS="--preview '$preview_dir'"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

if [[ -t 0 && -t 1 && -z ${ZSH_EXECUTION_STRING:-} ]]; then
  local key_bindings
  for key_bindings in \
    "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" \
    /usr/share/fzf/key-bindings.zsh \
    /usr/share/doc/fzf/examples/key-bindings.zsh; do
    [[ -r $key_bindings ]] && { source "$key_bindings"; break; }
  done
  unset key_bindings
fi

unset preview_file preview_dir
