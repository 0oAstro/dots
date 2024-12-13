{
  username,
  mac-app-util,
  ...
}: {
  # import sub modules
  imports = [
    ./terminal
    ./terminal/emulators/wezterm.nix
    ./terminal/emulators/kitty.nix
    mac-app-util.homeManagerModules.default
    ./gui.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";

    # Need to create aliases because Launchbar doesn't look through symlinks.
    # activation.link-apps = lib.hm.dag.entryAfter ["linkGeneration"] ''
    #   new_nix_apps="${config.home.homeDirectory}/Applications/Nix"
    #   rm -rf "$new_nix_apps"
    #   mkdir -p "$new_nix_apps"
    #   find -H -L "$genProfilePath/home-files/Applications" -name "*.app" -type d -print | while read -r app; do
    #     real_app=$(readlink -f "$app")
    #     app_name=$(basename "$app")
    #     target_app="$new_nix_apps/$app_name"
    #     echo "Alias '$real_app' to '$target_app'"
    #     ${pkgs.mkalias}/bin/mkalias "$real_app" "$target_app"
    #   done
    # '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
