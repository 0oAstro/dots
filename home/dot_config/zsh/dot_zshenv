#!/bin/zsh
#
# .zshenv — loaded for ALL zsh shells (interactive + non-interactive + scripts)
# Must be FORK-FREE. No external commands (date, mkdir, chmod, uname, id, test -x, etc.)
#

export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}
export SHELL_SESSIONS_DISABLE=1
export EDITOR=${EDITOR:-nvim}
export VISUAL=${VISUAL:-code}

# ── XDG base directories ────────────────────────────────────────
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-$UID}

# ── XDG app redirects (xdg-ninja / clean-home) ──────────────────
export CODEX_HOME=$XDG_CONFIG_HOME/codex
export PI_CODING_AGENT_DIR=$XDG_CONFIG_HOME/pi/agent
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NPM_CONFIG_INIT_MODULE=$XDG_CONFIG_HOME/npm/config/npm-init.js
export NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm
export BUNDLE_USER_CONFIG=$XDG_CONFIG_HOME/bundle
export BUNDLE_USER_PLUGIN=$XDG_DATA_HOME/bundle
export BUNDLE_USER_CACHE=$XDG_CACHE_HOME/bundle
export CP_HOME_DIR=$XDG_DATA_HOME/cocoapods
export ANDROID_USER_HOME=$XDG_DATA_HOME/android
export ANDROID_AVD_HOME=$XDG_DATA_HOME/android/avd
export NPM_CONFIG_TMP=$XDG_RUNTIME_DIR/npm

# ── Runtime tool homes ──────────────────────────────────────────
export CARGO_HOME=$XDG_DATA_HOME/cargo
export GOPATH=$XDG_DATA_HOME/go
export BUN_INSTALL=$XDG_DATA_HOME/bun
export RUSTUP_HOME=$XDG_DATA_HOME/rustup
export DOCKER_CONFIG=$XDG_CONFIG_HOME/docker
export LESSHISTFILE=$XDG_CACHE_HOME/less/history
export LESSKEY=$XDG_CONFIG_HOME/less/lesskey

# ── Platform detection (zero-fork: use $OSTYPE) ─────────────────
case $OSTYPE in
  darwin*)  export OS=macos ;;
  *)        export OS=unknown ;;
esac

# ── Antidote cache path ─────────────────────────────────────────
export ANTIDOTE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}/antidote

# ── Homebrew/Linuxbrew env (static, no brew shellenv fork) ───────
# Prefer exported HOMEBREW_PREFIX. Otherwise use common locations on each OS.
if [[ -z ${HOMEBREW_PREFIX:-} ]]; then
  case $OS in
    macos)
      [[ -d /opt/homebrew ]] && export HOMEBREW_PREFIX=/opt/homebrew
      [[ -z ${HOMEBREW_PREFIX:-} && -d /usr/local/Homebrew ]] && export HOMEBREW_PREFIX=/usr/local
      ;;
  esac
fi
if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  export HOMEBREW_PREFIX
  export HOMEBREW_CELLAR=${HOMEBREW_CELLAR:-$HOMEBREW_PREFIX/Cellar}
  export HOMEBREW_REPOSITORY=${HOMEBREW_REPOSITORY:-$HOMEBREW_PREFIX}
  export INFOPATH=$HOMEBREW_PREFIX/share/info:${INFOPATH:-}
fi

# ── PATH — zero-fork, all static ────────────────────────────────
path=(
  $HOME/.local/bin
  $HOME/.local/share/npm/bin
  $HOME/.local/share/cargo/bin
  $GOPATH/bin
  $CARGO_HOME/bin
  $path
)
# Homebrew/Linuxbrew if configured
[[ -n ${HOMEBREW_PREFIX:-} ]] && path=($HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin $path)

# pokemon freeting
export ZDOTS_GREETING=1

# .zprofile is login-only. Keep .zshenv fork-free and avoid running mkdir/chmod
# for every non-login interactive shell.
