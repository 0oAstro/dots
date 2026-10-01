# API keys. chezmoi decrypts encrypted_private_dot_zshrc.local.age (0oAstro/dots)
# into this 0600 file on apply, so startup only sources it. Threat model: age
# protects the secrets in the public repo, not on this machine.
[[ -r $ZDOTDIR/.zshrc.local ]] && source "$ZDOTDIR/.zshrc.local"

# Edit the encrypted source, then deploy and load it. chezmoi decrypts to a
# private temporary file; nvim gets no swap, undo or backup copies of it.
edit-secrets() {
  local editor=$EDITOR
  [[ ${EDITOR:t} == nvim ]] &&
    editor="$EDITOR -n -i NONE -c 'set noundofile nobackup nowritebackup noswapfile'"
  EDITOR=$editor VISUAL= chezmoi edit --apply "$ZDOTDIR/.zshrc.local" &&
    source "$ZDOTDIR/.zshrc.local"
}
