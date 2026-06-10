#!/bin/zsh
#
# 05-aliases.zsh — All aliases
#

alias e=$EDITOR
alias ga="git add" gb="git branch" gc="git commit"
alias gca="git commit --amend" gcm="git commit -m"
alias gco="git checkout" gd="git diff" gds="git diff --staged"
alias gp="git push" gpl="git pull" gl="git log"
alias gr="git rebase" gs="git status --short" gss="git status"
alias md="mkdir -p" rrm="command rm"
(( $+commands[trash] )) && alias rm=trash
alias ..="cd .."

# Directory stack aliases (Fish-like navigation via globalias expansion on Enter)
# ..2 → cd ../..   ..3 → cd ../../..   etc.
# 1 → cd -1         2 → cd -2          etc.
_dotdot=".."
for _index in {1..9}; do
  alias "$_index"="cd -${_index}"
  alias -g "..${_index}"="${_dotdot}"
  _dotdot+="/.."
done
unset _dotdot _index
alias _=sudo l=ls g=git
alias grep="${aliases[grep]:-grep} --exclude-dir={.git,.vscode}"
alias ping='ping -c 5' vi=vim
alias adb='HOME="$XDG_DATA_HOME"/android adb'
alias get=git quit=exit cd..='cd ..' zz=exit
alias ll='ls -lh' la='ls -lAh'
alias timestamp="date '+%Y-%m-%d %H:%M:%S'"
alias datestamp="date '+%Y-%m-%d'"
alias isodate="date +%Y-%m-%dT%H:%M:%S%z"
alias utc="date -u +%Y-%m-%dT%H:%M:%SZ"
alias unixepoch="date +%s"
alias print-fpath='for fp in $fpath; do echo $fp; done; unset fp'
alias print-path='echo $PATH | tr ":" "\n"'
alias print-functions='print -l ${(k)functions[(I)[^_]*]} | sort'
alias zshrc='$EDITOR "$ZDOTDIR"/.zshrc'
alias zbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'

# Conditional aliases (only if commands exist)
(( $+commands[python3] )) && ! (( $+commands[python] )) && alias python=python3
(( $+commands[pip3] )) && ! (( $+commands[pip] )) && alias pip=pip3
! (( $+commands[hd] )) && (( $+commands[hexdump] )) && alias hd="hexdump -C"
! (( $+commands[envsubst] )) && alias envsubst="python -c 'import os,sys;[sys.stdout.write(os.path.expandvars(l)) for l in sys.stdin]'"
