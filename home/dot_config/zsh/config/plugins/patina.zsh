# zsh-patina syntax highlighting.
#
# Activation also makes sure the highlighting daemon is running. Do not cache
# its output: sourcing cached shell code installs the ZLE hooks but skips that
# daemon lifecycle step, leaving highlighting silently inactive after it stops.

(( $+commands[zsh-patina] )) || return 0

# The daemon owns the loaded theme. Track both the selection and daemon PID so
# an external/manual daemon restart cannot leave our cheap theme marker lying.
_zdots_patina_marker=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/patina-theme
_zdots_patina_rundir=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/zsh-patina
# zsh-patina 1.8 uses daemon.pid; 1.9 stores the PID in daemon.lock.
if [[ -r $_zdots_patina_rundir/daemon.pid ]]; then
  _zdots_patina_pidfile=$_zdots_patina_rundir/daemon.pid
else
  _zdots_patina_pidfile=$_zdots_patina_rundir/daemon.lock
fi
_zdots_patina_active= _zdots_patina_pid=
[[ -r $_zdots_patina_pidfile ]] && IFS= read -r _zdots_patina_pid < $_zdots_patina_pidfile
[[ -r $_zdots_patina_marker ]] && IFS= read -r _zdots_patina_active < $_zdots_patina_marker
if [[ $_zdots_patina_active != $ZSH_PATINA_THEME\|$_zdots_patina_pid ||
      $ZSH_PATINA_CONFIG_PATH -nt $_zdots_patina_marker ||
      ( -n ${ZDOTS_THEME_FILE:-} && $ZDOTS_THEME_FILE -nt $_zdots_patina_marker ) ]]; then
  if zsh-patina restart >/dev/null 2>&1; then
    # `restart` daemonizes and can return before daemon.pid is replaced. Poll
    # only on this rare restart path; never bless the old PID as current.
    _zdots_patina_nextpid=
    for _zdots_patina_try in {1..50}; do
      [[ -r $_zdots_patina_pidfile ]] && IFS= read -r _zdots_patina_nextpid < $_zdots_patina_pidfile
      [[ -n $_zdots_patina_nextpid && $_zdots_patina_nextpid != $_zdots_patina_pid ]] && break
      command sleep 0.01
    done
    if [[ -n $_zdots_patina_nextpid && $_zdots_patina_nextpid != $_zdots_patina_pid ]]; then
      print -r -- "$ZSH_PATINA_THEME|$_zdots_patina_nextpid" >| $_zdots_patina_marker
    fi
  fi
fi
# Fast path: reuse a cached activation script when it provably matches the
# current install — same binary path (upgrades and reinstalls move it), same
# runtime dir, same config, and a live daemon. Any mismatch falls back to a
# fresh `zsh-patina activate`, which rewrites the cache, so this self-heals
# after upgrades. On this host the fork costs ~95 ms; sourcing the validated
# cache is ~1 ms.
_zdots_patina_cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/patina-activate.zsh
_zdots_patina_bin=${commands[zsh-patina]:-$(whence -p zsh-patina)}
_zdots_patina_key="# key: $_zdots_patina_bin ${XDG_RUNTIME_DIR:-} $ZSH_PATINA_CONFIG_PATH"
if [[ -r $_zdots_patina_cache && -n $_zdots_patina_bin ]] &&
  IFS= read -r _zdots_patina_first < "$_zdots_patina_cache" &&
  [[ $_zdots_patina_first == $_zdots_patina_key ]] &&
  { [[ -n $_zdots_patina_pid ]] && kill -0 -- $_zdots_patina_pid 2>/dev/null }
then
  source "$_zdots_patina_cache"
else
  _zdots_patina_out=$(zsh-patina activate)
  if [[ -n $_zdots_patina_out ]]; then
    # Refresh the validated cache for future shells (atomic replace).
    if _zdots_patina_tmp=$(command mktemp "$_zdots_patina_cache.XXXXXX" 2>/dev/null); then
      { print -r -- "$_zdots_patina_key"
        print -r -- "$_zdots_patina_out"
      } >| "$_zdots_patina_tmp" && command mv -f -- "$_zdots_patina_tmp" "$_zdots_patina_cache"
      [[ -n ${_zdots_patina_tmp:-} && -e $_zdots_patina_tmp ]] && command rm -f -- "$_zdots_patina_tmp"
    fi
    eval "$_zdots_patina_out"
  fi
fi

unset _zdots_patina_marker _zdots_patina_rundir _zdots_patina_pidfile \
  _zdots_patina_active _zdots_patina_pid _zdots_patina_nextpid _zdots_patina_try \
  _zdots_patina_cache _zdots_patina_bin _zdots_patina_key _zdots_patina_first \
  _zdots_patina_out _zdots_patina_tmp
