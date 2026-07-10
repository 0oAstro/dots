# macOS-only interactive integrations.

[[ $OSTYPE == darwin* ]] || return

local bw_sock=$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
[[ -S $bw_sock ]] && export SSH_AUTH_SOCK=$bw_sock

export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home
unset bw_sock
