{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      theme = "catppuccin-latte";

      font-family-italic = "DankMono Nerd Font";
      font-size = 18;

      macos-titlebar-style = "tabs";
      macos-titlebar-proxy-icon = "hidden";
      macos-option-as-alt = true;

      background-opacity = 0.90;
      background-blur-radius = 40;

      auto-update = "off";
      mouse-hide-while-typing = true;
      scrollback-limit = 1000000;

      window-save-state = "always";
    };

    # Keybindings need to be defined as an attribute set with unique keys
    keybinds = {
      "ctrl+n" = "new_window";

      "ctrl+h" = "goto_split:left";
      "ctrl+j" = "goto_split:bottom";
      "ctrl+k" = "goto_split:top";
      "ctrl+l" = "goto_split:right";

      "ctrl+a>h" = "new_split:left";
      "ctrl+a>j" = "new_split:down";
      "ctrl+a>k" = "new_split:up";
      "ctrl+a>l" = "new_split:right";
      "ctrl+a>f" = "toggle_split_zoom";

      "ctrl+a>n" = "next_tab";
      "ctrl+a>p" = "previous_tab";

      "super+r" = "reload_config";

      "shift+ctrl+left_bracket" = "previous_tab";
      "shift+ctrl+right_bracket" = "next_tab";
      "global:cmd+alt+`" = "toggle_quick_terminal";
    };
  };
}
