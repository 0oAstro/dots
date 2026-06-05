# ── macos — macOS-specific helpers ───────────────────────────────
# Adapted from mattmc3/zsh_custom

[[ "$OSTYPE" == darwin* ]] || return 0

fpath=($ZDOTDIR/functions $fpath)
autoload -Uz cdf flushdns hidefiles showfiles ofd pfd pfs lmk mand manp peek pushdf rmdsstore trash
