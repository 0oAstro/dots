# just is a command runner, Justfile is very similar to Makefile, but simpler.

# TODO update hostname here!
hostname := "aki"

############################################################################
#
#  Darwin related commands
#
############################################################################

darwin:
  nix build .#darwinConfigurations.{{hostname}}.system \
    --extra-experimental-features 'nix-command flakes'

  ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}}

darwin-debug:
  nix build .#darwinConfigurations.{{hostname}}.system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'

  ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}} --show-trace --verbose

############################################################################
#
#  nix related commands
#
############################################################################


update:
  nix flake update

history:
  nix profile history --profile /nix/var/nix/profiles/system

gc:
  # remove all generations older than 7 days
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

  # garbage collect all unused nix store entries
  sudo nix store gc --debug


fmt:
  # format the nix files in this repo
  nix fmt

clean:
  rm -rf result
