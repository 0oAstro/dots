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
    "$ZDOTDIR/.zsh_plugins.zsh" \
    "$ZDOTDIR"/lib/*.zsh(N) \
    "$ZDOTDIR"/config/**/*.zsh(N); do
    [[ -r $file ]] || continue
    zcompile "$file" && print "compiled ${file#$ZDOTDIR/}"
  done

  # Recompile Antidote-managed plugin files too. This refreshes stale plugin
  # bytecode after zsh upgrades without changing the normal startup path.
  for file in "$ANTIDOTE_HOME"/**/*.zsh(N-.); do
    [[ -r $file ]] || continue
    zcompile "$file" && print "compiled antidote/${file#$ANTIDOTE_HOME/}"
  done
}
