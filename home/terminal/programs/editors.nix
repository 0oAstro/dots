{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    neovim
    micro
    helix
  ];
}
