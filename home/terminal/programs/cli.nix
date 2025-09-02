{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # archives
    # zip
    # unzip
    p7zip

    # utils
    fd
    ripgrep
    darwin.trash

    aria2
    yt-dlp

    pokeget-rs

    (writeShellApplication {
      name = "launch";
      text = builtins.readFile ../scripts/launch;
    })
  ];
}
