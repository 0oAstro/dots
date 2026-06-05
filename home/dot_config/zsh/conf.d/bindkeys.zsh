# ── Key bindings ─────────────────────────────────────────────────
bindkey '^L' _pokeget_clear
bindkey '^R' fzf-history-widget
bindkey '^T' fzf-file-widget
bindkey '\ec' fzf-cd-widget

# Fish-style completion navigation
# ^P/^N are handled by bindkey-hss (history-substring-search)
bindkey '^I' menu-complete         # Tab to cycle completions
bindkey '^[[Z' reverse-menu-complete  # Shift-Tab to go back
