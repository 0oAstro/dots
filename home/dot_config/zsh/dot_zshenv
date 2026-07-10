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
if [[ -z ${XDG_RUNTIME_DIR:-} ]]; then
  case ${OSTYPE:-} in
    linux*) export XDG_RUNTIME_DIR=/run/user/$UID ;;
    *) export XDG_RUNTIME_DIR=${${TMPDIR:-/tmp}%/}/xdg-runtime-$UID ;;
  esac
fi

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

# ── PATH — zero-fork, all static ────────────────────────────────
# zsh normally does not de-duplicate $path. Keep this global so login +
# interactive startup cannot append the same XDG dirs twice.
typeset -gU path PATH
path=(
  $HOME/.local/bin
  $HOME/.local/share/npm/bin
  $HOME/.bun/bin
  $HOME/.cargo/bin
  $HOME/go/bin
  $path
)

# pokemon freeting
export ZDOTS_GREETING=1

# .zprofile is login-only. Keep .zshenv fork-free and avoid running mkdir/chmod
# for every non-login interactive shell.
