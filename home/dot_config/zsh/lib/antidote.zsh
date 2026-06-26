# Antidote bootstrap and static bundle generation.
#

local plugins_txt=$ZDOTDIR/.zsh_plugins.txt
local plugins_zsh=$ZDOTDIR/.zsh_plugins.zsh
local antidote_repo=$ZDOTDIR/.antidote

[[ -d $antidote_repo ]] || git clone --depth 1 --quiet https://github.com/mattmc3/antidote "$antidote_repo"

# Regenerate when the bundle list or cache root changes. The marker prevents a
# macOS-generated static bundle from being reused with Linux paths, or vice versa.
local marker first_line
marker="# ANTIDOTE_HOME=$ANTIDOTE_HOME"
if [[ -r $plugins_zsh ]]; then IFS= read -r first_line < "$plugins_zsh"; fi

if [[ -r $plugins_txt && (! -f $plugins_zsh || $plugins_txt -nt $plugins_zsh || $first_line != $marker) ]]; then
  fpath=("$antidote_repo/functions" "$antidote_repo" $fpath)
  autoload -Uz antidote
  { print -r -- "$marker"; antidote bundle < "$plugins_txt"; } >| "$plugins_zsh"
fi

unset plugins_txt plugins_zsh antidote_repo marker first_line
