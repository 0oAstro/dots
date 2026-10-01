# Install the real hooks at startup so builtin cd (including fzf's Alt-C)
# participates in directory history before the first explicit `z` command.
(( $+commands[zoxide] )) || return 0
_zdots_source_generated zoxide init zsh
alias cd=z
