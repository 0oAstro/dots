{pkgs, ...}: {
  programs.wezterm = {
    enable = true;

    # let homebrew manage this
    package = pkgs.emptyDirectory;

    enableBashIntegration = false;
    enableZshIntegration = false;

    extraConfig = ''
      local act = wezterm.action
      local font = "CartographCF Nerd Font"

      local weconfig = {}

      local mux = wezterm.mux

      local cache_dir = os.getenv('HOME') .. '/.cache/wezterm/'
      local window_size_cache_path = cache_dir .. 'window_size_cache.txt'


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

      wezterm.on("gui-startup", function()
       os.execute("mkdir " .. cache_dir)

       local window_size_cache_file = io.open(window_size_cache_path, "r")
       local window
       if window_size_cache_file ~= nil then
       	_, _, width, height = string.find(window_size_cache_file:read(), "(%d+),(%d+)")
       	_, _, window = mux.spawn_window({ width = tonumber(width), height = tonumber(height) })
       	window_size_cache_file:close()
       else
       	_, _, window = mux.spawn_window({})
       	window:gui_window():maximize()
       end
      end)

      wezterm.on("window-resized", function(_, pane)
      	local tab_size = pane:tab():get_size()
      	local cols = tab_size["cols"]
      	local rows = tab_size["rows"] + 2 -- Without adding the 2 here, the window doesn't maximize
      	local contents = string.format("%d,%d", cols, rows)

      	local window_size_cache_file = io.open(window_size_cache_path, "w")
      	-- Check if the file was successfully opened
      	if window_size_cache_file then
      		window_size_cache_file:write(contents)
      		window_size_cache_file:close()
      	else
      		print("Error: Could not open file for writing: " .. window_size_cache_path)
      	end
      end)

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
