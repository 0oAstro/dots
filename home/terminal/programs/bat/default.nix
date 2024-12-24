{
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      theme = "kanagawa";
    };
    # themes = let
    #   src-cat = pkgs.fetchFromGitHub {
    #     owner = "catppuccin";
    #     repo = "bat";
    #     rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
    #     hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
    #   };
    # in {
    #   Catppuccin-frappe = {
    #     inherit src-cat;
    #     file = "Catppuccin-frappe.tmTheme";
    #   };
    #   Catppuccin-latte = {
    #     inherit src-cat;
    #     file = "Catppuccin-latte.tmTheme";
    #   };
    # };
  };

  home.sessionVariables = {
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };

  xdg.configFile."bat/themes/kanagawa.tmTheme" = {
    source = ./themes/kanagawa.tmTheme;
  };
}
