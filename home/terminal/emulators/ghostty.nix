{...}: {
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "light:catppuccin-latte,dark:catppuccin-frappe";

      font-family-italic = "CartographCF Nerd Font";
      font-size = 14;

      macos-titlebar-style = "tabs";
      macos-titlebar-proxy-icon = "hidden";
      macos-option-as-alt = true;

      background-opacity = 0.96;
      background-blur-radius = 40;

      auto-update = "off";
    };
    keybindings = {
      "shift+ctrl+left_bracket" = "previous_tab";
      "shift+ctrl+right_bracket" = "next_tab";
    };
    extraConfig = ''
      keybind = global:cmd+`=toggle_quick_terminal
    '';
  };
}
