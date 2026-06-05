# ── zoxide ───────────────────────────────────────────────────────
eval "$(zoxide init zsh)"
alias cd=z

# ── ls override ──────────────────────────────────────────────────
ls() { eza -laH --icons --git --color=always "$@"; }
