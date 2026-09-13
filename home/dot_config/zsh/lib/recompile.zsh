# Optional bytecode refresh after editing configs. Zsh ignores stale bytecode.
recompile() {
  emulate -L zsh
  local file
  for file in "$ZDOTDIR"/.zshenv "$ZDOTDIR"/.zshrc "$ZDOTDIR"/.zstyles \
      "$ZDOTDIR"/.p10k.zsh "$ZDOTDIR"/.zsh_plugins.zsh \
      "$ZDOTDIR"/lib/*.zsh(N) "$ZDOTDIR"/config/**/*.zsh(N); do
    [[ -r $file ]] || continue
    zcompile "$file" || return
  done
}
