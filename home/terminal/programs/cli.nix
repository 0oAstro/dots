{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # archives
    zip
    unzip

    # utils
    fd
    ripgrep
    darwin.trash

    aria2
    yt-dlp

    pokeget-rs

    _1password-cli
  ];
}
