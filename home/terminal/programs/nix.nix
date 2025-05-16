{ pkgs, ... }:
# nix tooling
{
  home.packages = with pkgs; [
    # nix
    deadnix
    statix
    just
    nil
    nixfmt-rfc-style
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
