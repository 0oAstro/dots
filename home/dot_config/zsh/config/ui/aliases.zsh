# Aliases and Fish-like directory shortcuts.

alias e=$EDITOR
alias ga="git add" gb="git branch" gc="git commit"
alias gca="git commit --amend" gcm="git commit -m"
alias gco="git checkout" gd="git diff" gds="git diff --staged"
alias gp="git push" gpl="git pull" gl="git log"
alias gr="git rebase" gs="git status --short" gss="git status"
alias md="mkdir -p" rrm="command rm"
alias rm=trash
alias ..="cd .."
alias _=sudo l=ls g=git
alias grep='grep --exclude-dir={.git,.vscode}'
alias ping='ping -c 5' vi=vim
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
alias zbench='hyperfine --warmup 3 --runs 10 "zsh -lic exit"'
alias python=python3
alias pip=pip3
alias hd="hexdump -C"
alias envsubst="python -c 'import os,sys;[sys.stdout.write(os.path.expandvars(l)) for l in sys.stdin]'"

local dotdot=".."
local index
for index in {1..9}; do
  alias "$index"="cd -${index}"
  alias -g "..${index}"="$dotdot"
  dotdot+="/.."
done
unset dotdot index
