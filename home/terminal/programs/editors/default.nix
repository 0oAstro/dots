{
  neovim-nightly-overlay,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    micro

    neovim

    # NeoVim stuff and LSPs and Linters

    # lua
    luajit
    luajitPackages.luarocks
  ]; # ++ [ neovim-nightly-overlay.packages.${pkgs.system}.default ];

  imports = [
    ./helix
  ];
}
