{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    neovim
    micro
  ];

  imports = [
    ./helix
  ];
}
