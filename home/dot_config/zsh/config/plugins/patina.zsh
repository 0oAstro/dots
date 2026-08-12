# zsh-patina syntax highlighting.
#
# Activation also makes sure the highlighting daemon is running. Do not cache
# its output: sourcing cached shell code installs the ZLE hooks but skips that
# daemon lifecycle step, leaving highlighting silently inactive after it stops.

(( $+commands[zsh-patina] )) || return 0

# The daemon owns the loaded theme. Track both the selection and daemon PID so
# an external/manual daemon restart cannot leave our cheap theme marker lying.
_zdots_patina_marker=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/patina-theme
_zdots_patina_pidfile=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/zsh-patina/daemon.pid
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
unset _zdots_patina_marker _zdots_patina_pidfile _zdots_patina_active \
  _zdots_patina_pid _zdots_patina_nextpid _zdots_patina_try

eval "$(zsh-patina activate)"
