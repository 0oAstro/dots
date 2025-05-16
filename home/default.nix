{
  username,
  nix-index-database,
  ...
}:
{
  # import sub modules
  imports = [
    ./terminal
    ./terminal/emulators
    nix-index-database.hmModules.nix-index
  ];

  programs.nix-index.enable = true;

  # never index the developer folder in spotlight.
  home.file."Developer/.metadata_never_index".text = "";

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    # fuck that warning
    enableNixpkgsReleaseCheck = false;

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
