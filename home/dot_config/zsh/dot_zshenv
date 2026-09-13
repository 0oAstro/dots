#
# .zshenv — loaded for ALL zsh shells (interactive + non-interactive + scripts)
# Environment and shims only; interactive activation belongs in .zshrc.
#

export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}
export EDITOR=${EDITOR:-nvim}
export VISUAL=${VISUAL:-nvim}

# ── XDG base directories ────────────────────────────────────────
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

# Resolve the platform once. Later config uses this value instead of repeating
# OSTYPE checks across startup files.
typeset -g +x ZDOTS_PLATFORM=other
case ${OSTYPE:-} in
  darwin*)
    ZDOTS_PLATFORM=macos
    export SHELL_SESSIONS_DISABLE=1
    export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-${${TMPDIR:-/tmp}%/}/xdg-runtime-$UID}
    # Static Homebrew environment without the `brew shellenv` fork.
    export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-/opt/homebrew}
    export HOMEBREW_CELLAR=${HOMEBREW_CELLAR:-$HOMEBREW_PREFIX/Cellar}
    export HOMEBREW_REPOSITORY=${HOMEBREW_REPOSITORY:-$HOMEBREW_PREFIX}
    ;;
  linux*)
    ZDOTS_PLATFORM=linux
    export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$UID}
    ;;
  *)
    export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-${${TMPDIR:-/tmp}%/}/xdg-runtime-$UID}
    ;;
esac

# Make Bitwarden available to non-interactive SSH sessions too. Preserve a
# working inherited/forwarded agent; fall back only when its socket is absent.
if [[ $ZDOTS_PLATFORM == macos && ! -S ${SSH_AUTH_SOCK:-} ]]; then
  for _zdots_agent_socket in \
    "$HOME/.bitwarden-ssh-agent.sock" \
    "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"; do
    if [[ -S $_zdots_agent_socket ]]; then
      export SSH_AUTH_SOCK=$_zdots_agent_socket
      break
    fi
  done
  unset _zdots_agent_socket
fi

# Tool configuration needed by both interactive and noninteractive zsh.
export PROJECTS=${PROJECTS:-$HOME/Developer}
[[ -r $XDG_CONFIG_HOME/readline/inputrc ]] && export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config

# Pi: suppress startup version and package update notifications; updates are run manually.
export PI_SKIP_VERSION_CHECK=1

# XDG-aware tool homes
export BUNDLE_USER_CONFIG=$XDG_CONFIG_HOME/bundle
export BUNDLE_USER_CACHE=$XDG_CACHE_HOME/bundle
export BUNDLE_USER_PLUGIN=$XDG_DATA_HOME/bundle
[[ -r $XDG_CONFIG_HOME/npm/npmrc ]] && export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm
# npm 11 no longer supports NPM_CONFIG_TMP; discard stale inherited values.
unset NPM_CONFIG_INIT_MODULE NPM_CONFIG_TMP
export GOPATH=$XDG_DATA_HOME/go
export CP_HOME_DIR=$XDG_DATA_HOME/cocoapods
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export CARGO_HOME=$XDG_DATA_HOME/cargo
export RUSTUP_HOME=$XDG_DATA_HOME/rustup
export LESSHISTFILE=$XDG_STATE_HOME/lesshst
export TERMINFO=$XDG_DATA_HOME/terminfo
export TERMINFO_DIRS=/usr/share/terminfo

# Create only directories that zsh itself writes. Tool-specific directories are
# left to their owners, avoiding a long list of permanently cold startup checks.
for _zdots_dir in \
  "$XDG_CACHE_HOME/zsh" "$XDG_STATE_HOME/zsh"; do
  [[ -d $_zdots_dir ]] || command mkdir -p -- "$_zdots_dir" 2>/dev/null
done
[[ -d $GNUPGHOME ]] || command mkdir -m 700 -p -- "$GNUPGHOME" 2>/dev/null
[[ -d $XDG_RUNTIME_DIR ]] || command mkdir -m 700 -p -- "$XDG_RUNTIME_DIR" 2>/dev/null
unset _zdots_dir

# Avoid duplicate wireless-debug transports; use explicit `adb connect host:port`.
export ADB_MDNS_AUTO_CONNECT=0

# Amazon Bedrock defaults for the global Anthropic inference profiles.
# An explicit environment value still takes precedence.
export AWS_PROFILE=${AWS_PROFILE:-personal}
export AWS_REGION=${AWS_REGION:-us-east-1}

source "$ZDOTDIR/lib/path.zsh"
