# fx: `fx ask` uses ~/.fx/system.md (chezmoi-managed) as the system prompt; explicit --system passes through
fx() {
  if [ "$1" = "ask" ] && [[ "$*" != *--system* ]]; then
    shift
    command fx ask --system "$(cat $HOME/.fx/system.md)" "$@"
  else
    command fx "$@"
  fi
}
