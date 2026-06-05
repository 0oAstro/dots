#!/bin/zsh
#
# .zshenv — loaded for ALL shells
#

export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}

# XDG base directories
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

# PATH — available for all shells
path=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $HOME/.local/bin
  $HOME/.local/share/npm/bin
  $HOME/.local/share/cargo/bin
  $path
)

# Source .zprofile for non-login interactive shells
if [[ ! -o LOGIN ]] && [[ -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
