# macOS-only interactive integrations.

[[ $OSTYPE == darwin* ]] || return

# Homebrew paths (before system defaults so brew binaries win)
path=(
  $HOMEBREW_PREFIX/bin
  $HOMEBREW_PREFIX/sbin
  $HOMEBREW_PREFIX/opt/curl/bin
  $HOMEBREW_PREFIX/opt/libpq/bin
  $HOMEBREW_PREFIX/opt/mysql-client/bin
  $HOMEBREW_PREFIX/opt/sqlite/bin
  $path
)

local bw_sock=$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
[[ -S $bw_sock ]] && export SSH_AUTH_SOCK=$bw_sock

export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home
unset bw_sock
