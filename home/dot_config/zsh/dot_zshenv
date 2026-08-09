#
# .zshenv — loaded for ALL zsh shells (interactive + non-interactive + scripts)
# Keep this cheap; only missing XDG directories trigger an external command.
#

export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}
export SHELL_SESSIONS_DISABLE=1
export EDITOR=${EDITOR:-nvim}
export VISUAL=${VISUAL:-nvim}

# ── XDG base directories ────────────────────────────────────────
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

# Tool configuration needed by both interactive and noninteractive zsh.
export PROJECTS=${PROJECTS:-$HOME/Developer}
export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config

# XDG-aware tool homes
export BUNDLE_USER_CONFIG=$XDG_CONFIG_HOME/bundle
export BUNDLE_USER_CACHE=$XDG_CACHE_HOME/bundle
export BUNDLE_USER_PLUGIN=$XDG_DATA_HOME/bundle
export NPM_CONFIG_INIT_MODULE=$XDG_CONFIG_HOME/npm/config/npm-init.js
export NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm
export GOPATH=$XDG_DATA_HOME/go
export CP_HOME_DIR=$XDG_DATA_HOME/cocoapods
export GNUPGHOME=$XDG_DATA_HOME/gnupg
export CARGO_HOME=$XDG_DATA_HOME/cargo
export RUSTUP_HOME=$XDG_DATA_HOME/rustup
export LESSHISTFILE=$XDG_STATE_HOME/lesshst
export TERMINFO=$XDG_DATA_HOME/terminfo
export TERMINFO_DIRS=$XDG_DATA_HOME/terminfo:/usr/share/terminfo

if [[ -z ${XDG_RUNTIME_DIR:-} ]]; then
  case ${OSTYPE:-} in
    linux*) export XDG_RUNTIME_DIR=/run/user/$UID ;;
    *) export XDG_RUNTIME_DIR=${${TMPDIR:-/tmp}%/}/xdg-runtime-$UID ;;
  esac
fi
export NPM_CONFIG_TMP=$XDG_RUNTIME_DIR/npm
# Create the directories used by this config on first use. The directory checks
# keep the common path fork-free after the first shell.
for _zdots_dir in \
  "$XDG_CONFIG_HOME" "$XDG_CONFIG_HOME/readline" "$XDG_CONFIG_HOME/ripgrep" \
  "$XDG_CONFIG_HOME/bundle" "$XDG_CONFIG_HOME/npm/config" \
  "$XDG_CACHE_HOME" "$XDG_CACHE_HOME/zsh" "$XDG_CACHE_HOME/bundle" "$XDG_CACHE_HOME/npm" \
  "$XDG_DATA_HOME" "$XDG_DATA_HOME/zsh" "$XDG_DATA_HOME/bundle" "$XDG_DATA_HOME/go" \
  "$XDG_DATA_HOME/cocoapods" "$XDG_DATA_HOME/gnupg" "$XDG_DATA_HOME/cargo" \
  "$XDG_DATA_HOME/rustup" "$XDG_DATA_HOME/terminfo" \
  "$XDG_STATE_HOME" "$XDG_STATE_HOME/zsh" \
  "$XDG_RUNTIME_DIR/npm"; do
  [[ -d $_zdots_dir ]] || command mkdir -p -- "$_zdots_dir" 2>/dev/null
done
[[ -d $XDG_RUNTIME_DIR ]] || command mkdir -m 700 -p -- "$XDG_RUNTIME_DIR" 2>/dev/null
unset _zdots_dir

# Avoid duplicate wireless-debug transports; use explicit `adb connect host:port`.
export ADB_MDNS_AUTO_CONNECT=0

# Terminal color defaults
export COLORTERM=${COLORTERM:-truecolor}


# ── Antidote cache path ─────────────────────────────────────────
export ANTIDOTE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}/antidote

# ── Homebrew env (static, no brew shellenv fork or path probing) ──
export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-/opt/homebrew}
export HOMEBREW_CELLAR=${HOMEBREW_CELLAR:-$HOMEBREW_PREFIX/Cellar}
export HOMEBREW_REPOSITORY=${HOMEBREW_REPOSITORY:-$HOMEBREW_PREFIX}
[[ -d $ANTIDOTE_HOME ]] || command mkdir -p -- "$ANTIDOTE_HOME" 2>/dev/null

source "$ZDOTDIR/lib/path.zsh"
