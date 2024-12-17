{
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      theme = "$(defaults read -globalDomain AppleInterfaceStyle &> /dev/null && echo Catppuccin-frappe || echo Catppuccin-latte)";
    };
  };

  home.sessionVariables = {
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };
}
