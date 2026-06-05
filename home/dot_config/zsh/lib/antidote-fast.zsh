#
# antidote-fast.zsh — fast antidote bootstrap
# https://github.com/mattmc3/antidote
#

# Use cache dir for cloned repos
: ${ANTIDOTE_HOME:=${XDG_CACHE_HOME:-$HOME/.cache}/antidote}
ANTIDOTE_REPO=${ANTIDOTE_REPO:-${ZDOTDIR:-$HOME/.config/zsh}/.antidote}

# Clone antidote if necessary
if [[ ! -d $ANTIDOTE_REPO ]]; then
  git clone --depth 1 https://github.com/mattmc3/antidote $ANTIDOTE_REPO
fi

# Add antidote functions to fpath
fpath=($ANTIDOTE_REPO $fpath)
autoload -Uz antidote

# Generate static plugin file when .zsh_plugins.txt changes
zsh_plugins=${ZDOTDIR:-$HOME/.config/zsh}/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi

# Source the static plugin file
source ${zsh_plugins}.zsh
