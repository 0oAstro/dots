# Antidote bootstrap and static bundle generation.
#

local plugins_txt=$ZDOTDIR/.zsh_plugins.txt
local plugins_zsh=$ZDOTDIR/.zsh_plugins.zsh
local antidote_repo=$ZDOTDIR/.antidote

if [[ ! -d $antidote_repo ]]; then
  git clone --depth 1 --quiet https://github.com/mattmc3/antidote "$antidote_repo" || {
    print -ru2 -- 'zdots: unable to install Antidote'
    return 1
  }
fi

# Regenerate when the bundle list or cache root changes. The marker prevents a
# macOS-generated static bundle from being reused with Linux paths, or vice versa.
local marker first_line
marker="# ANTIDOTE_HOME=$ANTIDOTE_HOME"
if [[ -r $plugins_zsh ]]; then IFS= read -r first_line < "$plugins_zsh"; fi

if [[ -r $plugins_txt && (! -f $plugins_zsh || $plugins_txt -nt $plugins_zsh || $first_line != $marker) ]]; then
  fpath=("$antidote_repo/functions" "$antidote_repo" $fpath)
  autoload -Uz antidote
  local tmp
  tmp=$(command mktemp "$plugins_zsh.XXXXXX") || return 1
  if { print -r -- "$marker"; antidote bundle < "$plugins_txt"; } >| "$tmp"; then
    command mv -f -- "$tmp" "$plugins_zsh" || {
      command rm -f -- "$tmp"
      print -ru2 -- 'zdots: unable to install generated Antidote bundle'
      return 1
    }
  else
    command rm -f -- "$tmp"
    print -ru2 -- 'zdots: unable to generate Antidote bundle'
    return 1
  fi
fi

unset plugins_txt plugins_zsh antidote_repo marker first_line tmp
