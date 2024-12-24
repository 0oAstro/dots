{pkgs, ...}:
# nix tooling
{
  home.packages = with pkgs; [
    deadnix
    statix
    just
    nil
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };
}
