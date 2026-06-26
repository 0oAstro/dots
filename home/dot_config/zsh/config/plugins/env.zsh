# Environment consumed by sourced plugins.
#

# Skip autosuggestions widget rebinds on every precmd.
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
export ZSH_AUTOSUGGEST_USE_ASYNC=1

# zsh-autopair initializes eagerly; this lets our setup stay explicit.
export AUTOPAIR_INHIBIT_INIT=1

export ZSH_PATINA_CONFIG_PATH=$ZDOTDIR/config/plugins/zsh-patina.toml
