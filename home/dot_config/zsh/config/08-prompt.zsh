#!/bin/zsh
#
# 08-prompt.zsh — Directory backrefs
#

# ── Directory backrefs (..2 = ../.., 2 = cd -2) ─────────────────
typeset -g _dotdot=".."
for _index in {1..9}; do
  alias "$_index"="cd -${_index}"
  alias -g "..${_index}"="${_dotdot}"
  _dotdot+="/.."
done
unset _dotdot _index

# ── Never start in root ─────────────────────────────────────────
[[ "$PWD" != "/" ]] || cd

true
