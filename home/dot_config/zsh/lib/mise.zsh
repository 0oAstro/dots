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
#                 The leading `unset <TOOL>_HOME` lines are stripped as well:
#                 nested shells inherit correct tool env from their parent,
#                 and with hook-env deferred there is nothing to re-set them
#                 before the first prompt. Used by interactive shells only.

_zdots_mise_source() {
  emulate -L zsh
  setopt no_aliases
  local mode=$1

  local bin=$HOME/.local/bin/mise
  [[ -x $bin ]] || return 0

  local cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
  local full=$cache_dir/mise-activate-full.zsh
  local inter=$cache_dir/mise-activate-interactive.zsh
  local cfg_root=${MISE_GLOBAL_CONFIG_ROOT:-$HOME/.config/mise}
  local cfg=$cfg_root/config.toml

  # Regenerate when missing or stale. The binary mtime catches mise upgrades;
  # config.toml/dir mtimes catch tool additions and removals, which change the
  # PATH export embedded in the activate script.
  local stale=0 f
  for f in $full $inter; do
    [[ -r $f ]] || stale=1
    [[ $bin -nt $f ]] && stale=1
    [[ -f $cfg && $cfg -nt $f ]] && stale=1
    [[ -d $cfg_root && $cfg_root -nt $f ]] && stale=1
  done

  if (( stale )); then
    local tmp
    if tmp=$(command mktemp "$full.XXXXXX" 2>/dev/null); then
      if "$bin" activate zsh >| "$tmp" && [[ -s $tmp ]]; then
        command mv -f -- "$tmp" "$full"
        if tmp=$(command mktemp "$inter.XXXXXX" 2>/dev/null); then
          command sed \
            -e 's/^_mise_hook$/true # deferred to first precmd/' \
            -e '/^export __MISE_ZSH_ACTIVATE_PATH=/d' \
            -e '/^export __MISE_ZSH_ACTIVATE_ENV=/d' \
            -e '/^unset CLOUDSDK_ROOT_DIR$/d' \
            -e '/^unset GOBIN$/d' \
            -e '/^unset GOROOT$/d' \
            -e '/^unset JAVA_HOME$/d' \
            -e '/^unset RUSTUP_TOOLCHAIN$/d' \
            -- "$full" >| "$tmp" &&
            command mv -f -- "$tmp" "$inter"
        fi
      else
        command rm -f -- "$tmp" 2>/dev/null
        # Generation failed; fall back to a direct activation rather than
        # silently skipping mise entirely.
        eval "$("$bin" activate zsh)"
        return 0
      fi
    fi
  fi

  if [[ $mode == interactive && -r $inter ]]; then
    source "$inter"
  elif [[ -r $full ]]; then
    source "$full"
  fi
}
