# Install the real hooks at startup so builtin cd (including fzf's Alt-C)
# participates in directory history before the first explicit `z` command.
_zdots_source_generated zoxide init zsh
# Only hijack cd when the hooks actually loaded; a corrupted cache left z()
# defined without __zoxide_z and broke every cd.
(( $+functions[__zoxide_z] )) && alias cd=z
