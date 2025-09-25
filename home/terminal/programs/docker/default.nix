{pkgs, ...}: {
  imports = [
    ./lazydocker.nix
  ];

  # programs.docker-cli = {
  #   enable = true;
  # };

  home.packages = [pkgs.docker-client];
}
