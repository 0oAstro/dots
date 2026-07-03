# Linux-only interactive integrations.
[[ $OSTYPE == linux* ]] || return

# Bind to the GNOME Keyring / gcr ssh-agent managed by systemd.
# systemd knows this socket but doesn't export it into non-graphical
# shells (tmux, ssh, etc.), so wire it up ourselves.
if [[ -z $SSH_AUTH_SOCK ]]; then
  local gcr_sock="${XDG_RUNTIME_DIR:-/run/user/$UID}/gcr/ssh"
  [[ -S $gcr_sock ]] && export SSH_AUTH_SOCK=$gcr_sock
  unset gcr_sock
fi

# Auto-load every keypair in ~/.ssh into the agent. (N) = nullglob,
# :r strips the .pub suffix so we hand ssh-add the private-key paths.
# All keys are passphrase-less, so this is non-interactive; ssh-add
# skips keys already in the agent.
[[ -n $SSH_AUTH_SOCK ]] && ssh-add -- ~/.ssh/*.pub(N:r) >/dev/null 2>&1
