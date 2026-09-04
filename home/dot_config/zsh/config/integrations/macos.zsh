# macOS-only interactive integrations.

local bw_sock=$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
[[ -S $bw_sock ]] && export SSH_AUTH_SOCK=$bw_sock
unset bw_sock

source "$ZDOTDIR/config/ui/clipboard.zsh"
[[ -n ${KITTY_WINDOW_ID:-} ]] && source "$ZDOTDIR/config/integrations/remote-kitty.zsh"
