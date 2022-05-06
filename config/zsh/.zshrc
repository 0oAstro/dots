# bash tresitter works good
# vim:set ft=bash:

[[ $- != *i* ]] && return

# completions
fpath+=$ZDOTDIR/plugin/zsh-completions/src

# per directory history
source $ZDOTDIR/plugin/per-directory-history.zsh

# fsh
source $ZDOTDIR/plugin/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Style the completion a bit
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Show a prompt on selection
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
# Use arrow keys in completion list
zstyle ':completion:*' menu select
# Group results by category
zstyle ':completion:*' group-name ''
# Keep directories and files separated
zstyle ':completion:*' list-dirs-first true
# Add colors to processes for kill completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# match uppercase from lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Filename suffixes to ignore during completion (except after rm command)
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.c~' '*?.old' '*?.pro'

# command for process lists, the local web server details and host completion
# on processes completion complete all user processes
zstyle ':completion:*:processes' command 'ps -au$USER'

# Completion formatting and messages
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'

# case insensitive tab completion
zstyle ':completion:*' completer _complete _ignored _approximate
zstyle ':completion:*' list-colors '\'
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' verbose true
_comp_options+=(globdots)

HISTFILE=$HOME/.local/share/zsh_hist
HISTSIZE=1000
SAVEHIST=1000
setopt autocd share_history extended_history hist_ignoredups
# Show an error when a globbing expansion doesn't find any match
setopt nomatch
# List on ambiguous completion and Insert first match immediately
setopt autolist menucomplete
# Use pushd when cd-ing around
setopt autopushd pushdminus pushdsilent
# Use single quotes in string without the weird escape tricks
setopt rcquotes
# Single word commands can resume an existing job
setopt autoresume
# Append commands to history as they are exectuted
setopt inc_append_history_time
# Remove useless whitespace from commands
setopt hist_reduce_blanks
# Those options aren't wanted
unsetopt beep extendedglob notify

autoload -Uz compinit
compinit

# fzf-tab
source $ZDOTDIR/plugin/fzf-tab/fzf-tab.plugin.zsh
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# substring search
source $ZDOTDIR/plugin/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# suggestions
source $ZDOTDIR/plugin/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^ ' autosuggest-execute


### EXPORT
export TERM="xterm-256color"                      # getting proper colors
export HISTCONTROL=ignoredups:erasedups           # no duplicate entries
export ALTERNATE_EDITOR="vim"                     # setting for emacsclient
export EDITOR="hx"                                # $EDITOR use Emacs in terminal
export VISUAL="nvim"                              # $VISUAL use Emacs in GUI mode
export GPG_TTY=$(tty)

### FZF
export FZF_DEFAULT_OPTS="--prompt='# ' --layout=reverse --multi --sort --bind '?:toggle-preview' --bind 'ctrl-a:select-all' --color=bg+:#302D41,bg:#1E1E2E,spinner:#F8BD96,hl:#F28FAD --color=fg:#D9E0EE,header:#F28FAD,info:#DDB6F2,pointer:#F8BD96 --color=marker:#F8BD96,fg+:#F2CDCD,prompt:#DDB6F2,hl+:#F28FAD --bind 'ctrl-e:execute(echo {+} | xargs -o nvim)' --height=80% --preview-window=:hidden --info=inline --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'"
export FZF_DEFAULT_COMMAND="fd --hidden --type f --exclude '.git' --exclude '.pnpm-store' --exclude 'node_modules'"
### SET MANPAGER
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
man() {
    command man "$@" | eval ${MANPAGER}
}

### PATH
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
export SPICETIFY_INSTALL="/home/astro/.spicetify"
export PATH="$PATH:/home/astro/.spicetify"

### CHANGE TITLE OF TERMINALS
case ${TERM} in
  xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|alacritty|st|konsole*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'
        ;;
  screen*)
    PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\033\\"'
    ;;
esac

### ARCHIVE EXTRACTION
# usage: ex <file>
ex ()
{
  if [ -f "$1" ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   unzstd $1    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

### ALIASES ###

# navigation
up () {
  local d=""
  local limit="$1"

  # Default to limit of 1
  if [ -z "$limit" ] || [ "$limit" -le 0 ]; then
    limit=1
  fi

  for ((i=1;i<=limit;i++)); do
    d="../$d"
  done

  # perform cd. Show error if cd fails
  if ! cd "$d"; then
    echo "Couldn't go up $limit dirs.";
  fi
}

# vim and emacs
alias nv="nvim"

# Changing "ls" to "exa"
alias ls='exa -alHG --icons --git --color=always --group-directories-first' # my preferred listing
alias la='exa -a --color=always --group-directories-first'  # all files and dirs
alias ll='exa -l --color=always --group-directories-first'  # long format
alias lt='exa -aT --color=always --group-directories-first' # tree listing
alias l.='exa -a | egrep "^\."'

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Dangerous alias
alias rm='rip'

# adding flags
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB

# ps
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# Merge Xresources
alias merge='xrdb -merge $HOME/.Xresources'

# git
alias addup='git add -u'
alias addall='git add .'
alias branch='git branch'
alias checkout='git checkout'
alias clone='git clone'
alias commit='git commit -m'
alias fetch='git fetch'
alias pull='git pull origin'
alias push='git push origin'
alias stat='git status'  # 'status' is protected name so using 'stat' instead
alias tag='git tag'
alias newtag='git tag -a'

# temp dir
alias tmp='cd $(mktemp -d)'

# reload
alias zs='source $ZDOTDIR/.zshrc'

# exclude out history
alias sx=' sx'

# the terminal rickroll
alias rr='curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash'

# rust
[[ -f $HOME/.cargo/env ]] && source ~/.cargo/env

# evalcache
source $ZDOTDIR/plugin/evalcache.plugin.zsh

# starship
evalcache starship init zsh

# zoxide
evalcache zoxide init zsh

# the fuck
evalcache thefuck --alias --enable-experimental-instant-mode
