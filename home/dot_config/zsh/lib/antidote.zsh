#
# antidote.zsh — fallback antidote bootstrap (dynamic)
# https://github.com/mattmc3/antidote
#

: ${ANTIDOTE_HOME:=${XDG_CACHE_HOME:-$HOME/.cache}/antidote}
ANTIDOTE_REPO=${ANTIDOTE_REPO:-${ZDOTDIR:-$HOME/.config/zsh}/.antidote}

zstyle ':antidote:home' path $ANTIDOTE_HOME
zstyle ':antidote:repo' path $ANTIDOTE_REPO
zstyle ':antidote:bundle' path-style full
zstyle ':antidote:*' zcompile 'yes'

# Clone antidote if necessary
if [[ ! -d $ANTIDOTE_REPO ]]; then
  git clone --depth 1 https://github.com/mattmc3/antidote $ANTIDOTE_REPO
fi

source $ANTIDOTE_REPO/antidote.zsh
antidote load
