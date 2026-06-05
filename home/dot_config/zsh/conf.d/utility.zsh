# ── utility — cross-platform aliases + helpers ───────────────────
# Adapted from mattmc3/zsh_custom

[[ "$TERM" != 'dumb' ]] || return 0

# Ensure python commands exist (no fork — uses $commands assoc array)
(( $+commands[python3] )) && ! (( $+commands[python] )) && alias python=python3
(( $+commands[pip3] )) && ! (( $+commands[pip] )) && alias pip=pip3

# Ensure hd (hex dump) exists
! (( $+commands[hd] )) && (( $+commands[hexdump] )) && alias hd="hexdump -C"

# envsubst fallback (no fork — alias, only evaluates when called)
! (( $+commands[envsubst] )) && alias envsubst="python -c 'import os,sys;[sys.stdout.write(os.path.expandvars(l)) for l in sys.stdin]'"

# Cross-platform sed -i (no fork — checks GNU sed via $OSTYPE)
if [[ "$OSTYPE" == darwin* ]]; then
  alias sedi="sed -i ''"
else
  alias sedi="sed -i"
fi
