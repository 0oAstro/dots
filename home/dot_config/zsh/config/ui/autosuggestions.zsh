# Autosuggestion-specific widget integration.

ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(
  globalias-accept
  globalias-space
  accept-full-suggestion
  accept-line-plain
)

# Allow multi-byte Alt/arrow sequences to arrive over remote connections.
KEYTIMEOUT=20
