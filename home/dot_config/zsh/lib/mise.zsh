# Cached mise activation.
#
# `eval "$(mise activate zsh)"` costs ~150 ms on this host: the activate fork
# plus the hook-env fork it triggers are ~20 ms each on this Xeon, and every
# shell re-runs them. The activate output depends only on the mise binary and
# the mise configuration, so it is cached under $XDG_CACHE_HOME/zsh and
# regenerated whenever either is newer than the cache.
#
# Two variants are kept:
#
#   full        — verbatim `mise activate zsh` output; applies the tool env
#                 (JAVA_HOME, GOROOT, ...) synchronously. Required for
#                 non-interactive shells, which never run precmd hooks.
#
#   interactive — identical except the startup `_mise_hook` call and the
#                 `__MISE_ZSH_ACTIVATE_*` snapshot exports are disabled, so
#                 the (~68 ms) hook-env fork is deferred to the first precmd.
#                 Used by interactive shells only.

_zdots_mise_source() {
  emulate -L zsh
  setopt no_aliases
  local mode=$1

  local bin=${commands[mise]:-}
  [[ -x $bin ]] || return 0

  local cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
  local full=$cache_dir/mise-activate-full.zsh
  local inter=$cache_dir/mise-activate-interactive.zsh
  local cfg_root=${MISE_GLOBAL_CONFIG_ROOT:-$HOME/.config/mise}
  local cfg=$cfg_root/config.toml
  # Nested shells inherit mise's environment. Generate from its saved base PATH
  # with activation bookkeeping removed so the cache is identical whether it is
  # refreshed by a top-level or nested shell.
  local base_path=${__MISE_ORIG_PATH:-$PATH}

  # Regenerate when missing or stale. The binary mtime catches mise upgrades;
  # config.toml/dir mtimes catch tool additions and removals, which change the
  # PATH export embedded in the activate script.
  local key="# mise-cache=v2 bin=$bin"
  local stale=0 f first_line
  for f in $full $inter; do
    [[ -r $f ]] || stale=1
    [[ $bin -nt $f ]] && stale=1
    [[ -f $cfg && $cfg -nt $f ]] && stale=1
    [[ -d $cfg_root && $cfg_root -nt $f ]] && stale=1
    if [[ -r $f ]]; then
      IFS= read -r first_line < "$f"
      [[ $first_line == $key ]] || stale=1
    fi
  done

  if (( stale )); then
    local tmp_full= tmp_inter=
    tmp_full=$(command mktemp "$full.XXXXXX" 2>/dev/null) &&
      tmp_inter=$(command mktemp "$inter.XXXXXX" 2>/dev/null)
    if [[ -n $tmp_full && -n $tmp_inter ]] &&
      { print -r -- "$key"
        command env \
          -u MISE_SHELL -u __MISE_ORIG_PATH -u __MISE_DIFF -u __MISE_SESSION \
          -u __MISE_ZSH_PRECMD_RUN -u __MISE_ZSH_CHPWD_RAN \
          -u __MISE_ZSH_ACTIVATE_PATH -u __MISE_ZSH_ACTIVATE_ENV \
          PATH="$base_path" "$bin" activate zsh
      } >| "$tmp_full" &&
      command sed \
        -e 's/^_mise_hook$/true # deferred to first precmd/' \
        -e '/^export __MISE_ZSH_ACTIVATE_PATH=/d' \
        -e '/^export __MISE_ZSH_ACTIVATE_ENV=/d' \
        -- "$tmp_full" >| "$tmp_inter" &&
      [[ -s $tmp_full && -s $tmp_inter ]] &&
      command mv -f -- "$tmp_full" "$full" &&
      command mv -f -- "$tmp_inter" "$inter"; then
      :
    else
      command rm -f -- ${tmp_full:-} ${tmp_inter:-} 2>/dev/null
      # Generation failed; fall back to direct activation rather than silently
      # skipping mise for this shell.
      eval "$(command env \
        -u MISE_SHELL -u __MISE_ORIG_PATH -u __MISE_DIFF -u __MISE_SESSION \
        -u __MISE_ZSH_PRECMD_RUN -u __MISE_ZSH_CHPWD_RAN \
        -u __MISE_ZSH_ACTIVATE_PATH -u __MISE_ZSH_ACTIVATE_ENV \
        PATH="$base_path" "$bin" activate zsh)"
      return 0
    fi
  fi

  if [[ $mode == interactive && -r $inter ]]; then
    source "$inter"
  elif [[ -r $full ]]; then
    source "$full"
  fi
}
