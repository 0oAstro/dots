# Prompt setup.
#
# Pure is sourced by Antidote from .zsh_plugins.txt. Pure calls its own setup
# function when sourced, which avoids promptinit's fpath scan.

# pure has no right prompt; avoid stale RPROMPT from other themes.
RPROMPT=
