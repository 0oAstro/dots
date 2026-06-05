# ── common-aliases — useful everyday aliases ─────────────────────
# Adapted from mattmc3/zsh_custom. Non-conflicting with aliases.zsh.

# Single-char shortcuts
alias _=sudo
alias l=ls
alias g=git

# Mask built-ins with better defaults
alias grep="${aliases[grep]:-grep} --exclude-dir={.git,.vscode}"
alias ping='ping -c 5'
alias vi=vim

# Fix common typos
alias get=git
alias quit='exit'
alias cd..='cd ..'
alias zz='exit'

# More ways to ls
alias ll='ls -lh'
alias la='ls -lAh'

# Date/time stamps
alias timestamp="date '+%Y-%m-%d %H:%M:%S'"
alias datestamp="date '+%Y-%m-%d'"
alias isodate="date +%Y-%m-%dT%H:%M:%S%z"
alias utc="date -u +%Y-%m-%dT%H:%M:%SZ"
alias unixepoch="date +%s"

# Print things
alias print-fpath='for fp in $fpath; do echo $fp; done; unset fp'
alias print-path='echo $PATH | tr ":" "\n"'
alias print-functions='print -l ${(k)functions[(I)[^_]*]} | sort'
alias zshrc='${EDITOR:-vim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'

# Directory backrefs: ..2 = ../..,  ..3 = ../../.., etc.
# dirstack: 1 = cd -1,  2 = cd -2,  etc.
typeset -g _dotdot=".."
for _index in {1..9}; do
  alias "$_index"="cd -${_index}"
  alias -g "..${_index}"="${_dotdot}"
  _dotdot+="/.."
done
unset _dotdot _index
