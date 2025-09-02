{ ... }: {
  imports = [
    ./lazydocker.nix
  ];

  programs.docker-cli = {
    enable = true;
  };
}
