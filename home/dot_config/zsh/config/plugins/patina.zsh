# zsh-patina syntax highlighting.
#
# `zsh-patina activate` forks the binary and re-emits identical shell code on
# every startup. Its output is deterministic, so cache it and source the cache.
#
# Upstream warns against caching because the emitted code bakes in absolute
# paths: the binary location and a daemon socket under $XDG_RUNTIME_DIR. Both
# go into the marker below, so a cache built for one is never reused for
# another, and `-nt` covers in-place upgrades of the binary itself.

(( $+commands[zsh-patina] )) || return 0

() {
  emulate -L zsh
  setopt local_options no_aliases

  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/patina-activate.zsh
  local bin=$commands[zsh-patina]
  local marker first_line
  marker="# key: $bin ${XDG_RUNTIME_DIR:-} ${ZSH_PATINA_CONFIG_PATH:-}"

  [[ -r $cache ]] && IFS= read -r first_line < "$cache"

  if [[ $first_line != $marker || $bin -nt $cache ]]; then
    command mkdir -p -- "${cache:h}" 2>/dev/null
    { print -r -- "$marker"; zsh-patina activate } >| "$cache" || return 1
    zcompile -R -- "$cache" 2>/dev/null
  fi

  source "$cache"
}
