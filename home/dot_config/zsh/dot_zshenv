#
# .zshenv — loaded for ALL zsh shells (interactive + non-interactive + scripts)
# Keep this cheap; only missing XDG directories trigger an external command.
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

# Tool configuration needed by both interactive and noninteractive zsh.
export PROJECTS=${PROJECTS:-$HOME/Developer}
export INPUTRC=$XDG_CONFIG_HOME/readline/inputrc
export TAILSCALE_TAILNET=${TAILSCALE_TAILNET:-kitty-armadillo.ts.net}
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config

if [[ -z ${XDG_RUNTIME_DIR:-} ]]; then
  case ${OSTYPE:-} in
    linux*) export XDG_RUNTIME_DIR=/run/user/$UID ;;
    *) export XDG_RUNTIME_DIR=${${TMPDIR:-/tmp}%/}/xdg-runtime-$UID ;;
  esac
fi

# Create the directories used by this config on first use. The directory checks
# keep the common path fork-free after the first shell.
for _zdots_dir in \
  "$XDG_CONFIG_HOME" "$XDG_CONFIG_HOME/readline" "$XDG_CONFIG_HOME/ripgrep" \
  "$XDG_CACHE_HOME" "$XDG_CACHE_HOME/zsh" \
  "$XDG_DATA_HOME" "$XDG_DATA_HOME/zsh" \
  "$XDG_STATE_HOME" "$XDG_STATE_HOME/zsh"; do
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
export INFOPATH=$HOMEBREW_PREFIX/share/info:${INFOPATH:-}
[[ -d $ANTIDOTE_HOME ]] || command mkdir -p -- "$ANTIDOTE_HOME" 2>/dev/null

# ── PATH — Apple Silicon Homebrew + user tools ─────────────────
# zsh normally does not de-duplicate $path. Keep this global so login +
# interactive startup cannot append the same XDG dirs twice.
typeset -gU path PATH
path=(
  $HOMEBREW_PREFIX/bin
  $HOMEBREW_PREFIX/sbin
  $HOMEBREW_PREFIX/opt/curl/bin
  $HOMEBREW_PREFIX/opt/libpq/bin
  $HOMEBREW_PREFIX/opt/mysql-client/bin
  $HOMEBREW_PREFIX/opt/sqlite/bin
  $HOME/.local/bin
  $HOME/.bun/bin
  $HOME/.cargo/bin
  $HOME/go/bin
  $path
)

# .zprofile is login-only. Keep login-only work there; the guarded directory
# bootstrap above avoids running mkdir after the first shell creates the paths.
