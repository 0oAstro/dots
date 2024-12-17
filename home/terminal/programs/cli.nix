{pkgs, ...}: {
  home.packages = with pkgs; [
    # archives
    zip
    unzip

    # utils
    fd
    file
    ripgrep
    darwin.trash

    aria2
    yt-dlp
    mas

    pokeget-rs
  ];

  programs = {
    eza = {
      enable = true;
      git = true;
    };
    ssh = {
      enable = true;
      extraConfig = ''
        Host *
          AddKeysToAgent yes
          UseKeychain yes
          IdentityFile ~/.ssh/id_ed25519
      '';
    };
  };
}
