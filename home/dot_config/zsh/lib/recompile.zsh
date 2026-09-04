# Compile frequently sourced files. Zsh automatically uses adjacent .zwc files
# when they are newer than the source.
#

recompile() {
  emulate -L zsh
  local file
  for file in \
    "$ZDOTDIR/.zshenv" \
    "$ZDOTDIR/.zshrc" \
    "$ZDOTDIR/.zstyles" \
    "$ZDOTDIR/.p10k.zsh" \
    "$ZDOTDIR/.zsh_plugins.zsh" \
    "$ZDOTDIR"/lib/*.zsh(N) \
    "$ZDOTDIR"/config/**/*.zsh(N); do
    [[ -r $file ]] || continue
    zcompile "$file" && print "compiled ${file#$ZDOTDIR/}"
  done

  # Refresh decrypted secrets cache too, if the secrets integration has been loaded.
  # This keeps the next shell on the fast warm path after secret/dotfile changes.
  if (( $+functions[_zdots_build_secrets_cache] )); then
    _zdots_build_secrets_cache && print "refreshed secrets cache"
  fi

  # Recompile only plugin files that contributed functions to this shell. The
  # cache can retain disabled plugins, so walking all of ANTIDOTE_HOME does
  # needless work on fzf-tab, autopair, old prompts, and their test fixtures.
  local -a plugin_files
  typeset -U plugin_files
  plugin_files=( ${(M)${(v)functions_source}:#${~ANTIDOTE_HOME}/*} )
  for file in $plugin_files; do
    [[ -r $file ]] || continue
    zcompile "$file" && print "compiled antidote/${file#$ANTIDOTE_HOME/}"
  done

  # prune stale zcompdump files from old remote hosts
  local -a stale_dumps=( $XDG_CACHE_HOME/zsh/zcompdump-*(Nm+30) )
  stale_dumps=( ${stale_dumps:#(${ZSH_COMPDUMP}|${ZSH_COMPDUMP}.zwc)} )
  if (( $#stale_dumps )); then
    command rm -f -- $stale_dumps
    print "pruned $#stale_dumps stale zcompdump file(s)"
  fi
}
