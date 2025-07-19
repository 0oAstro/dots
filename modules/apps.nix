{ pkgs, ... }:
{
  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  # TODO Feel free to modify this file to fit your needs.
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    git
  ];

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [
      "apple/apple"
    ];

    # `brew install --cask
    casks = [
      "1password"
      "appcleaner"
      "brave-browser@nightly"
      "cursor"
      "etrecheckpro"
      "ghostty"
      "google-drive"
      "hammerspoon"
      "heroic"
      "hoppscotch"
      "iina"
      "imageoptim"
      "keycastr"
      "maccy"
      "maestral"
      "mechvibes"
      "notion"
      "obsidian"
      "raycast"
      "slack"
      "spotify"
      "standard-notes"
      "steam"
      "tor-browser"
      "tunnelblick"
      "vesktop"
      "whatsapp"
      "zed@preview"
      "zen@twilight"
    ];

    masApps = {
      "XCode" = 497799835;
      "Microsoft PowerPoint" = 462062816;
    };

    caskArgs = {
      no_quarantine = true;
    };
  };
}
