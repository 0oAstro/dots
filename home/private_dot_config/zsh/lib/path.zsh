# Sourced by .zshenv and again by .zprofile: macOS path_helper (/etc/zprofile)
# hoists the system bindirs above Homebrew's in between. `typeset -U` keeps the
# leftmost entry, so sourcing twice is idempotent.

typeset -gU path PATH fpath FPATH
# -x is required: unlike PATH, INFOPATH is not a special exported parameter.
typeset -gxUT INFOPATH infopath

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

# Git's shell helpers source `gettext.sh` by name. Mise creates shims for every
# executable in every installed tool version, including an inactive Anaconda
# gettext.sh; sourcing that binary shim produces Mach-O garbage as shell code.
# Prefer Homebrew's real shell library while leaving Mise ahead for other tools.
if [[ $ZDOTS_PLATFORM == macos && -x $HOMEBREW_PREFIX/opt/gettext/bin/gettext.sh ]]; then
  path=($HOMEBREW_PREFIX/opt/gettext/bin $path)
fi

if [[ -n ${HOMEBREW_PREFIX:-} && -d $HOMEBREW_PREFIX/share/info ]]; then
  infopath=($HOMEBREW_PREFIX/share/info $infopath)
fi
