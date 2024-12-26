{
  neovim-nightly-overlay,
  pkgs,
  ...
}: {
  home.packages = [
    pkgs.micro

    neovim-nightly-overlay.packages.${pkgs.system}.default
    pkgs.luajit
    pkgs.luajitPackages.luarocks
  ];

  imports = [
    ./helix
  ];
}
