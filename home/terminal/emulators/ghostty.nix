{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      theme = "Kanagawa Wave";

      font-family-italic = "Liga SFMono Nerd Font";
      font-size = 18;

      macos-titlebar-style = "tabs";
      macos-titlebar-proxy-icon = "hidden";
      macos-option-as-alt = true;

      background-opacity = 0.96;
      background-blur-radius = 40;

      auto-update = "off";
      keybind = [
        "shift+ctrl+left_bracket=previous_tab"
        "shift+ctrl+right_bracket=next_tab"
        "global:cmd+alt+`=toggle_quick_terminal"
      ];
    };
  };
}
