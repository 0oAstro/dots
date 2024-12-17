{config, ...}: let
  data = config.xdg.dataHome;
  conf = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in {
  imports = [
    ./programs
    ./shell
  ];

  # add environment variables
  home = {
    sessionVariables = {
      # clean up ~
      LESSHISTFILE = "${cache}/less/history";
      LESSKEY = "${conf}/less/lesskey";

      WINEPREFIX = "${data}/wine";
      XAUTHORITY = "$XDG_RUNTIME_DIR/Xauthority";

      EDITOR = "nvim";
      DIRENV_LOG_FORMAT = "";

      # auto-run programs using nix-index-database
      NIX_AUTO_RUN = "1";

      # My projects directory
      PROJECTS = "~/Developer";
    };
    sessionPath = [
      "/opt/homebrew/bin"
      "/Applications/Ghostty.app/Contents/MacOS/"
    ];
  };
}
