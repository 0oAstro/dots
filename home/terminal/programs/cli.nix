{pkgs, ...}: {
  home.packages = with pkgs; [
    # archives
    # zip
    # unzip
    p7zip

    # anime
    ani-cli

    # the whale
    docker-client # using colima to manage it on backend side

    # utils
    fd
    ripgrep
    darwin.trash

    # downloaders
    aria2
    yt-dlp
    ffmpeg

    # pokeget
    pokeget-rs

    # custom scripts
    (writeShellApplication {
      name = "launch";
      text = builtins.readFile ../../../scripts/launch;
    })
  ];
}
