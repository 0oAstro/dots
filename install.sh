#!/bin/sh
# Set up this machine from 0oAstro/dots:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/0oAstro/dots/master/install.sh)"
# Safe to rerun. It bootstraps only what Ansible cannot do unattended (mise,
# GitHub login, the age key, Homebrew's installer), then runs the playbook
# for this host, which applies chezmoi at the end. Servers are better set up
# from another machine: add them to ansible/inventory.yml and run
# `mise run provision -- --limit <host>` there.
#
# DOTS_REPO overrides the repo, for example a file:// URL when testing.
# DOTS_GROUP is the inventory group for a host not yet listed in
# ansible/inventory.yml (default: macs on macOS, desktops on Linux).
set -eu

bin=$HOME/.local/bin
mise=$bin/mise
key=$HOME/.config/age/keys.txt
repo=${DOTS_REPO:-0oAstro/dots}
src=$HOME/.local/share/chezmoi
host=$(uname -n | cut -d. -f1 | tr '[:upper:]' '[:lower:]')

say() { printf '\033[1;34mdots:\033[0m %s\n' "$*"; }
# Piped installs have no stdin, so prompts read the terminal when there is one.
if (: </dev/tty) 2>/dev/null; then tty=/dev/tty; else tty=; fi

if [ ! -x "$mise" ]; then
  say "installing mise to $mise"
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$mise" sh
fi

# mise downloads release assets from GitHub and the agent setup clones
# private repos; both use this login.
gh() { "$mise" exec gh@latest -- gh "$@"; }
if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  if [ -n "$tty" ]; then
    say "logging in to GitHub"
    gh auth login --hostname github.com --git-protocol https --web <"$tty" ||
      say "GitHub login failed; private repos will fail to clone"
  else
    say "not logged in to GitHub; private repos will fail to clone"
  fi
fi

# The age key decrypts API keys, SSH host lists and server secrets. Without
# it, everything else still applies; add the key later and rerun.
if [ ! -f "$key" ] && [ -n "$tty" ]; then
  say "paste the age key (AGE-SECRET-KEY-...), or press Enter to skip"
  IFS= read -r secret <"$tty" || secret=
  case $secret in
    AGE-SECRET-KEY-*)
      mkdir -p "${key%/*}"
      (umask 077 && printf '%s\n' "$secret" >"$key")
      ;;
    '') say "skipping secrets" ;;
    *) say "that is not an age secret key; skipping secrets" ;;
  esac
fi

# Homebrew's installer refuses root and asks for the sudo password itself.
if [ "$(uname -s)" = Darwin ] && [ ! -x /opt/homebrew/bin/brew ]; then
  say "installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" <"${tty:-/dev/null}"
fi

# chezmoi clones with its built-in git, so a fresh Mac needs no Xcode tools
# yet. Ansible rewrites the config with this host's switches.
if [ ! -d "$src/.git" ]; then
  say "cloning $repo"
  "$mise" exec chezmoi@latest -- chezmoi init --use-builtin-git=true --no-tty --promptDefaults "$repo"
fi

cd "$src"
"$mise" trust --quiet mise.toml
"$mise" run ansible:deps

set -- --limit "$host"
if ! "$mise" exec -- ansible-inventory -i ansible/inventory.yml --host "$host" >/dev/null 2>&1; then
  case $(uname -s) in Darwin) group=${DOTS_GROUP:-macs} ;; *) group=${DOTS_GROUP:-desktops} ;; esac
  extra=$(mktemp -d)/inventory.yml # the yaml plugin needs the extension
  printf 'all:\n  children:\n    %s:\n      hosts:\n        %s:\n' "$group" "$host" >"$extra"
  set -- "$@" -i inventory.yml -i "$extra"
  say "$host is not in ansible/inventory.yml; using group $group for this run (add it and commit)"
fi
if ! sudo -n true 2>/dev/null; then
  set -- "$@" --ask-become-pass
fi

say "provisioning $host"
"$mise" run provision -- "$@" <"${tty:-/dev/null}"
