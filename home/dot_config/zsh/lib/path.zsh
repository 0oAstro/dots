# PATH construction, shared by .zshenv and .zprofile.
#
# macOS runs /usr/libexec/path_helper from /etc/zprofile after ~/.zshenv, which
# hoists the system bindirs above Homebrew's. Re-sourcing this from .zprofile
# restores the intended order; `typeset -U` keeps the leftmost entry, so the
# repeated assignment is idempotent.

typeset -gU path PATH fpath FPATH
# -x is required: unlike PATH, INFOPATH is not a special exported parameter.
typeset -gxUT INFOPATH infopath

path=(
  $HOMEBREW_PREFIX/bin
  $HOMEBREW_PREFIX/sbin
  $HOMEBREW_PREFIX/opt/curl/bin
  $HOMEBREW_PREFIX/opt/libpq/bin
  $HOMEBREW_PREFIX/opt/mysql-client/bin
  $HOMEBREW_PREFIX/opt/sqlite/bin
  $HOME/.local/bin
  $HOME/.local/share/pnpm/bin
  $HOME/.bun/bin
  $CARGO_HOME/bin
  $GOPATH/bin
  $path
)

infopath=($HOMEBREW_PREFIX/share/info $infopath)
