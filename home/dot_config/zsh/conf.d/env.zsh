# ── Environment ──────────────────────────────────────────────────
export CLICOLOR=1
export DIRENV_LOG_FORMAT=""
export PROJECTS="$HOME/Developer"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export GOPATH="$XDG_DATA_HOME/go"
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
export LESSKEY="$XDG_CONFIG_HOME/less/lesskey"

# ── History file ─────────────────────────────────────────────────
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=100000
export SAVEHIST=100000

# ── Cargo env (trusted) ──────────────────────────────────────────
[[ -f "$CARGO_HOME/env" ]] && source "$CARGO_HOME/env"
