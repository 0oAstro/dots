{ ... }: {
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "light:catppuccin-latte,dark:catppuccin-frappe";

      font-family-italic = "";
      font-family-bold-italic = "";
      font-size = 14;
      window-title-font-family = "";

      macos-titlebar-style = "tabs";
      macos-titlebar-proxy-icon = "hidden";
      macos-option-as-alt = true;

      background-opacity = 0.96;
      background-blur-radius = 40;
    };
    keybindings = {
      "global:cmd+`" = "toggle_quick_terminal";
      "shift+ctrl+left_bracket" = "previous_tab";
      "shift+ctrl+right_bracket" = "next_tab";
    };
  };
}
