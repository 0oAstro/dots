{pkgs, ...}: {
  home.packages = with pkgs; [
    neovim
    micro
    helix
  ];
}
