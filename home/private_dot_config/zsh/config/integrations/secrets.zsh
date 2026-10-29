# API keys. chezmoi decrypts encrypted_private_agents.env.age (0oAstro/dots)
# into ~/.config/secrets/agents.env (0600), plain NAME=value lines that systemd
# units also read. Shells export only the allowlist in .zshenv, so npm scripts
# and other children don't inherit every key. Threat model: age protects the
# secrets in the public repo, not on this machine.

# Export the named keys into this shell: `secret DEEPGRAM_API_KEY`.
secret() {
  local secrets=$HOME/.config/secrets/agents.env name line
  for name in "$@"; do
    line=${(M)${(f)"$(<$secrets)"}:#$name=*}
    if [[ -z $line ]]; then
      print -u2 "secret: $name is not in $secrets"
      return 1
    fi
    eval "export $line"
  done
}

# Edit the encrypted source, then deploy it. chezmoi decrypts to a private
# temporary file; nvim gets no swap, undo or backup copies of it.
edit-secrets() {
  local editor=$EDITOR
  [[ ${EDITOR:t} == nvim ]] &&
    editor="$EDITOR -n -i NONE -c 'set noundofile nobackup nowritebackup noswapfile'"
  EDITOR=$editor VISUAL= chezmoi edit --apply "$HOME/.config/secrets/agents.env"
}
