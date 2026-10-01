#!/bin/sh
# Set up a new machine from 0oAstro/dots:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/0oAstro/dots/master/install.sh)"
# Safe to rerun. Extra arguments go to `chezmoi init`, for example --branch.
set -eu

bin=$HOME/.local/bin
mise=$bin/mise
key=$HOME/.config/age/keys.txt

say() { printf '\033[1;34mdots:\033[0m %s\n' "$*"; }

if [ ! -x "$mise" ]; then
  say "installing mise to $mise"
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$mise" sh
fi

# The agent modules clone private repos, and mise downloads release assets
# from GitHub. Both use this login, so do it before the first apply.
gh() { "$mise" exec aqua:cli/cli@latest -- gh "$@"; }
if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  say "logging in to GitHub"
  gh auth login --hostname github.com --git-protocol https --web </dev/tty ||
    say "not logged in to GitHub; private agent repos will fail to clone"
fi

# The age key decrypts API keys and SSH host lists. Without it, everything
# else still applies; add the key later and run `chezmoi apply`.
if [ ! -f "$key" ] && : </dev/tty 2>/dev/null; then
  say "paste the age key (AGE-SECRET-KEY-...), or press Enter to skip"
  IFS= read -r secret </dev/tty || secret=
  case $secret in
    AGE-SECRET-KEY-*)
      mkdir -p "${key%/*}"
      (umask 077 && printf '%s\n' "$secret" >"$key")
      ;;
    '') say "skipping secrets" ;;
    *) say "that is not an age secret key; skipping secrets" ;;
  esac
fi

say "applying 0oAstro/dots"
exec "$mise" exec chezmoi@latest -- chezmoi init --apply "$@" 0oAstro/dots
