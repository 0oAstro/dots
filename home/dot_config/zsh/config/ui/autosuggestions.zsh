# Autosuggestion-specific widget integration.

ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(
  globalias-accept
  globalias-space
  accept-full-suggestion
  _zfh_fzf_history
  _zfh_fzf_dir_history
  accept-line-plain
)

KEYTIMEOUT=1
bindkey -M emacs '^[' autosuggest-clear
