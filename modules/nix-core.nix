{pkgs, ...}: {
  nix = {
    extraOptions = ''
      # for direnv GC roots
      keep-outputs = true
      keep-derivations = true
    '';
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    settings = {
      # enable flakes globally
      experimental-features = ["nix-command" "flakes"];

      # garbage collection
      auto-optimise-store = true;

      # substituers that will be considered before the official ones(https://cache.nixos.org)
      substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      builders-use-substitutes = true;
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  nixpkgs.config.allowUnfree = true;
}
