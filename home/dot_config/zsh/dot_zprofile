#!/bin/zsh
#
# .zprofile — sourced for login shells only
#

export SHELL_SESSIONS_DISABLE=1
# ── Runtime dir ─────────────────────────────────────────────────
# Linux: /run/user/$UID is managed by logind/systemd; don't try to create it.
# macOS: create our temp-backed runtime dir for tools that expect XDG_RUNTIME_DIR.
case $OS in
  macos)
    [[ -d $XDG_RUNTIME_DIR ]] || mkdir -p $XDG_RUNTIME_DIR 2>/dev/null
    [[ -O $XDG_RUNTIME_DIR ]] && chmod 700 $XDG_RUNTIME_DIR 2>/dev/null
    ;;
esac
