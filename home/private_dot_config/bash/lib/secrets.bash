# API keys: the 0600 file chezmoi decrypts for zsh ($ZDOTDIR/.zshrc.local).
_zdots_secrets=${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.local
[[ -r $_zdots_secrets ]] && source "$_zdots_secrets"
unset _zdots_secrets
