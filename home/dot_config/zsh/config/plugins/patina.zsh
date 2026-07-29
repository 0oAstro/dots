# zsh-patina syntax highlighting.
#
# Activation also makes sure the highlighting daemon is running. Do not cache
# its output: sourcing cached shell code installs the ZLE hooks but skips that
# daemon lifecycle step, leaving highlighting silently inactive after it stops.

(( $+commands[zsh-patina] )) || return 0

eval "$(zsh-patina activate)"
