{pkgs, ...}: {
  home.packages = with pkgs; [
    neovim
    micro

    luajit
    luajitPackages.luarocks
  ];

  imports = [
    ./helix
  ];
}
