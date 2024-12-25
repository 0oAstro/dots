{pkgs, ...}: {
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "${pkgs.eza}/bin/eza -laHG --icons --git";
      tmp = "cd (mktemp -d)";
      ".." = "cd ..";
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


      # Kanagawa Fish shell theme
      # A template was taken and modified from Tokyonight:
      # https://github.com/folke/tokyonight.nvim/blob/main/extras/fish_tokyonight_night.fish
      set -l foreground DCD7BA normal
      set -l selection 2D4F67 brcyan
      set -l comment 727169 brblack
      set -l red C34043 red
      set -l orange FF9E64 brred
      set -l yellow C0A36E yellow
      set -l green 76946A green
      set -l purple 957FB8 magenta
      set -l cyan 7AA89F cyan
      set -l pink D27E99 brmagenta

      # Syntax Highlighting Colors
      set -g fish_color_normal $foreground
      set -g fish_color_command $cyan
      set -g fish_color_keyword $pink
      set -g fish_color_quote $yellow
      set -g fish_color_redirection $foreground
      set -g fish_color_end $orange
      set -g fish_color_error $red
      set -g fish_color_param $purple
      set -g fish_color_comment $comment
      set -g fish_color_selection --background=$selection
      set -g fish_color_search_match --background=$selection
      set -g fish_color_operator $green
      set -g fish_color_escape $pink
      set -g fish_color_autosuggestion $comment

      # Completion Pager Colors
      set -g fish_pager_color_progress $comment
      set -g fish_pager_color_prefix $cyan
      set -g fish_pager_color_completion $foreground
      set -g fish_pager_color_description $comment

      # brew
      set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
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

  # xdg.configFile."fish/themes/Catppuccin-Frappe.theme" = {
  #   source = ./themes/Catppuccin-Frappe.theme;
  # };
  # xdg.configFile."fish/themes/Catppuccin-Latte.theme" = {
  #   source = ./themes/Catppuccin-Latte.theme;
  # };
  # xdg.configFile."fish/themes/Catppuccin-Mocha.theme" = {
  #   source = ./themes/Catppuccin-Mocha.theme;
  # };
  # xdg.configFile."fish/themes/Catppuccin-Macchiato.theme" = {
  #   source = ./themes/Catppuccin-Macchiato.theme;
  # };
}
