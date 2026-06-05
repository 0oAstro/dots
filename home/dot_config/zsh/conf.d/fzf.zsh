# ── fzf ─────────────────────────────────────────────────────────
export FZF_CTRL_T_OPTS="--preview 'bat --color=always {}'"
export FZF_ALT_C_OPTS="--preview 'eza --all --color=always --tree --level=2 {}'"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
