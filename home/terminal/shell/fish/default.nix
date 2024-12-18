{pkgs, ...}: {
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "${pkgs.eza}/bin/eza -laHG --icons --git";
      tmp = "cd (mktemp -d)";
      ".." = "cd ..";
      bat = "bat --theme=(defaults read -globalDomain AppleInterfaceStyle &> /dev/null && echo Catppuccin-frappe || echo Catppuccin-latte)";
    };
    shellAbbrs = {
      e = "$EDITOR";
      ga = "git add";
      gb = "git branch";
      gc = "git commit";
      gca = "git commit --amend";
      gcm = "git commit -m";
      gco = "git checkout";
      gd = "git diff";
      gds = "git diff --staged";
      gp = "git push";
      gpl = "git pull";
      gl = "git log";
      gr = "git rebase";
      gs = "git status --short";
      gss = "git status";

      md = "mkdir -p";
      rm = "trash"; # I am used to rm but rip is :noice:
    };
    plugins = [
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair;
      }
    ];
    interactiveShellInit = ''
      # colorscript
      function fish_greeting
        ${pkgs.pokeget-rs}/bin/pokeget random --hide-name
      end

      # GPG TTY
      export GPG_TTY=(tty)

      # choose theme
      fish_config theme choose (defaults read -globalDomain AppleInterfaceStyle &> /dev/null && echo "Catppuccin-Frappe" || echo "Catppuccin-Latte")
    '';
    functions = {
      lwhich = {
        description = "Show the full path of a command, resolving links along the way";
        body = "readlink -f (which $argv[1])";
      };

      mkcd = {
        description = "Make and enter a directory";
        body = ''
          if test (count $argv) -ne 1
              echo "mkcd: Expected exactly one argument."
              return 127
          else
              mkdir $argv[1] && cd $argv[1]
          end
        '';
      };
    };
  };

  xdg.configFile."fish/themes/Catppuccin-Frappe.theme" = {
    source = ./themes/Catppuccin-Frappe.theme;
  };
  xdg.configFile."fish/themes/Catppuccin-Latte.theme" = {
    source = ./themes/Catppuccin-Latte.theme;
  };
  xdg.configFile."fish/themes/Catppuccin-Mocha.theme" = {
    source = ./themes/Catppuccin-Mocha.theme;
  };
  xdg.configFile."fish/themes/Catppuccin-Macchiato.theme" = {
    source = ./themes/Catppuccin-Macchiato.theme;
  };
}
