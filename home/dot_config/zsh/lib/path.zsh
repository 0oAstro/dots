# PATH construction, shared by .zshenv and .zprofile.
#
# macOS runs /usr/libexec/path_helper from /etc/zprofile after ~/.zshenv, which
# hoists the system bindirs above Homebrew's. Re-sourcing this from .zprofile
# restores the intended order; `typeset -U` keeps the leftmost entry, so the
# repeated assignment is idempotent.

typeset -gU path PATH fpath FPATH
# -x is required: unlike PATH, INFOPATH is not a special exported parameter.
typeset -gxUT INFOPATH infopath

# Homebrew is a macOS-only path source. Keep its default prefix from
# polluting Linux shells.
if [[ -n ${HOMEBREW_PREFIX:-} && -d $HOMEBREW_PREFIX ]]; then
  path=(
    $HOMEBREW_PREFIX/bin
    $HOMEBREW_PREFIX/sbin
    $path
  )
fi

path=(
  $HOME/.local/share/mise/shims
  $HOME/.local/bin
  $HOME/.local/share/pnpm/bin
  $CARGO_HOME/bin
  $GOPATH/bin
  $path
)

if [[ -n ${HOMEBREW_PREFIX:-} && -d $HOMEBREW_PREFIX/share/info ]]; then
  infopath=($HOMEBREW_PREFIX/share/info $infopath)
fi
