#!/bin/zsh
#
# 01-plugins.zsh — Antidote static plugin source
#

local _plugins=$ZDOTDIR/.zsh_plugins.zsh

# Performance: skip autosuggestions widget re-bind on every precmd
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Inhibit autopair auto-init — it inits eagerly, redundant call in widgets is harmless
export AUTOPAIR_INHIBIT_INIT=1

[[ -r $_plugins ]] && source $_plugins

unset AUTOPAIR_INHIBIT_INIT _plugins
