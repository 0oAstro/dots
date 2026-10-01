# systemd runs the gcr ssh-agent but doesn't export its socket to non-graphical
# shells (tmux, ssh). No ssh-add: the keys are passphrase-less and ~/.ssh/config
# pins IdentityFile + IdentitiesOnly per host, so loading every key would only
# widen what gets offered.
if [[ -z $SSH_AUTH_SOCK ]]; then
  local gcr_sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/gcr/ssh"
  [[ -S $gcr_sock ]] && export SSH_AUTH_SOCK=$gcr_sock
  unset gcr_sock
fi
