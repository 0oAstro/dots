# Settings consumed by sourced plugins.
#

# Skip autosuggestions widget rebinds on every precmd.
typeset -g +x ZSH_AUTOSUGGEST_MANUAL_REBIND=1
typeset -g +x ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
unset ZSH_AUTOSUGGEST_USE_ASYNC  # Async is the plugin default on supported zsh versions.
