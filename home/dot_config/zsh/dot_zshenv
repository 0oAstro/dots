#
# .zshenv — loaded for ALL zsh shells (interactive + non-interactive + scripts)
# Must be FORK-FREE. No external commands (date, mkdir, chmod, uname, id, test -x, etc.)
#

export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}
export SHELL_SESSIONS_DISABLE=1
export EDITOR=${EDITOR:-nvim}
export VISUAL=${VISUAL:-zed-preview}

# ── XDG base directories ────────────────────────────────────────
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$UID}

# ── XDG app redirects (xdg-ninja / clean-home) ──────────────────
export CODEX_HOME=$XDG_CONFIG_HOME/codex
export PI_CODING_AGENT_DIR=$XDG_CONFIG_HOME/pi/agent
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NPM_CONFIG_INIT_MODULE=$XDG_CONFIG_HOME/npm/config/npm-init.js
export NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm
if [[ -n ${XDG_RUNTIME_DIR:-} ]]; then
  export NPM_CONFIG_TMP=$XDG_RUNTIME_DIR/npm
fi
export BUNDLE_USER_CONFIG=$XDG_CONFIG_HOME/bundle
export BUNDLE_USER_PLUGIN=$XDG_DATA_HOME/bundle
export BUNDLE_USER_CACHE=$XDG_CACHE_HOME/bundle
export CP_HOME_DIR=$XDG_DATA_HOME/cocoapods
export ANDROID_USER_HOME=$XDG_DATA_HOME/android
export ANDROID_AVD_HOME=$XDG_DATA_HOME/android/avd
export AZURE_CONFIG_DIR=$XDG_DATA_HOME/azure
export CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude
export AWS_CONFIG_FILE=$XDG_CONFIG_HOME/aws/config
export AWS_SHARED_CREDENTIALS_FILE=$XDG_CONFIG_HOME/aws/credentials
export GNUPGHOME=$XDG_DATA_HOME/gnupg

# ── Terminal color/terminfo defaults ────────────────────────────
# xdg-ninja-friendly terminfo location. Point directly at XDG_DATA_HOME so
# tools do not fail on missing/default TERMINFO_DIRS entries.
export TERMINFO=${TERMINFO:-$XDG_DATA_HOME/terminfo}
unset TERMINFO_DIRS
export COLORTERM=${COLORTERM:-truecolor}

# ── Runtime tool homes ──────────────────────────────────────────
export CARGO_HOME=$XDG_DATA_HOME/cargo
export GOPATH=$XDG_DATA_HOME/go
export BUN_INSTALL=$XDG_DATA_HOME/bun
export RUSTUP_HOME=$XDG_DATA_HOME/rustup
export DOCKER_CONFIG=$XDG_CONFIG_HOME/docker
export LESSHISTFILE=$XDG_CACHE_HOME/less/history
export LESSKEY=$XDG_CONFIG_HOME/less/lesskey

# ── Antidote cache path ─────────────────────────────────────────
export ANTIDOTE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}/antidote

# ── Homebrew env (static, no brew shellenv fork or path probing) ──
export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-/opt/homebrew}
export HOMEBREW_CELLAR=${HOMEBREW_CELLAR:-$HOMEBREW_PREFIX/Cellar}
export HOMEBREW_REPOSITORY=${HOMEBREW_REPOSITORY:-$HOMEBREW_PREFIX}
export INFOPATH=$HOMEBREW_PREFIX/share/info:${INFOPATH:-}

# ── PATH — zero-fork, all static ────────────────────────────────
# zsh normally does not de-duplicate $path. Keep this global so login +
# interactive startup cannot append the same XDG dirs twice.
typeset -gU path PATH
path=(
  $HOME/.local/bin
  $HOME/.local/share/npm/bin
  $BUN_INSTALL/bin
  $HOME/.local/share/cargo/bin
  $GOPATH/bin
  $CARGO_HOME/bin
  $path
)
path=($HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin $path)

# pokemon freeting
export ZDOTS_GREETING=1

# .zprofile is login-only. Keep .zshenv fork-free and avoid running mkdir/chmod
# for every non-login interactive shell.
