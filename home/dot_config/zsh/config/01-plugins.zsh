#!/bin/zsh
#
# 01-plugins.zsh — Antidote static plugin source
#

local _plugins=$ZDOTDIR/.zsh_plugins.zsh

# Performance: skip autosuggestions widget re-bind on every precmd
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Inhibit autopair auto-init — we'll call it in deferred hook
export AUTOPAIR_INHIBIT_INIT=1

[[ -r $_plugins ]] && source $_plugins

unset AUTOPAIR_INHIBIT_INIT _plugins
