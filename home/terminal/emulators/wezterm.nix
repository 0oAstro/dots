{pkgs, ...}:

{
  programs.wezterm = {
    enable = true;

    # let homebrew manage this
    package = pkgs.emptyDirectory;

    enableBashIntegration = false;
    enableZshIntegration = false;

    extraConfig = ''
      local act = wezterm.action
      local font = "CartographCF Nerd Font"

      local config = {}

      local function scheme_for_appearance(appearance)
          if appearance:find "Dark" then
              return "Catppuccin Mocha"
          else
              return "Catppuccin Latte"
          end
      end

      if wezterm.config_builder then
          config = wezterm.config_builder()
      end

      config.font_size = 16
      config.window_background_opacity = 0.6
      config.macos_window_background_blur = 40
      config.hide_tab_bar_if_only_one_tab = true
      config.audible_bell = "Disabled"
      config.window_close_confirmation = "NeverPrompt"
      config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
      config.font = wezterm.font(font, { weight = "Regular", stretch = "Normal", style = "Normal" })
      config.enable_tab_bar = true
      config.window_decorations = 'RESIZE'
      config.term = 'wezterm'

      return config
    '';
  };
}
