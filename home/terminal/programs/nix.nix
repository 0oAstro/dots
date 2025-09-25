{
  pkgs,
  username,
  ...
}:
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
    silent = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 1d --keep 3";
    flake = "/Users/${username}/Developer/dots";
  };
}
