
{pkgs, ...}: {
  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  # TODO Fell free to modify this file to fit your needs.
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
      "homebrew/services"
      "nikitabobko/tap"
    ];

    # `brew install --cask`
    casks = [
      "appcleaner"
      "arc"
      "discord"
      "etrecheckpro"
      "iina"
      "imageoptim"
      "keycastr"
      "kitty"
      "maccy"
      "maestral"
      "notion"
      "notion-calendar"
      "protonvpn"
      "standard-notes"
      "stremio"
      "transmission"
      "tunnelblick"
      "visual-studio-code"
      "wezterm"
      "whisky"
    ];

    masApps = {
        WhatsApp = 310633997;
        "Microsoft Word" = 462054704;
        "Microsoft Excel" = 462058435;
        "Microsoft PowerPoint" = 462062816;
        "DaVinci Resolve" = 571213070;
        Bitwarden = 1352778147;
    };

    caskArgs.no_quarantine = true;
  };
}
