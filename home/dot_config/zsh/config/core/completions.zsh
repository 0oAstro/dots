# Completion styles. compinit itself is handled by mattmc3/ez-compinit.
#

zstyle ':completion:*' menu select=2
zstyle ':completion:*' group-name '' verbose yes
zstyle ':completion:*' completer _complete _ignored _approximate
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

_comp_options+=(globdots)
ZSH_COMPDUMP=$XDG_CACHE_HOME/zsh/zcompdump-$HOST
