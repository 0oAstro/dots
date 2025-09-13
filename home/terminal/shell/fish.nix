{ pkgs, ... }:
{
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
      tf = "thefuck";
    };
    plugins = [
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair;
      }
    ];
    interactiveShellInit = ''
      # Catppuccin Mocha
      set -g fish_color_normal cdd6f4
      set -g fish_color_command 89b4fa
      set -g fish_color_param f2cdcd
      set -g fish_color_keyword f38ba8
      set -g fish_color_quote a6e3a1
      set -g fish_color_redirection f5c2e7
      set -g fish_color_end fab387
      set -g fish_color_comment 7f849c
      set -g fish_color_error f38ba8
      set -g fish_color_gray 6c7086
      set -g fish_color_selection --background=313244
      set -g fish_color_search_match --background=313244
      set -g fish_color_option a6e3a1
      set -g fish_color_operator f5c2e7
      set -g fish_color_escape eba0ac
      set -g fish_color_autosuggestion 6c7086
      set -g fish_color_cancel f38ba8
      set -g fish_color_cwd f9e2af
      set -g fish_color_user 94e2d5
      set -g fish_color_host 89b4fa
      set -g fish_color_host_remote a6e3a1
      set -g fish_color_status f38ba8
      set -g fish_pager_color_progress 6c7086
      set -g fish_pager_color_prefix f5c2e7
      set -g fish_pager_color_completion cdd6f4
      set -g fish_pager_color_description 6c7086

      # brew
      set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d

      # any-nix-shell
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
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

      # fish greeting
      fish_greeting = {
        description = "Show a random Pokémon";
        body = ''
          ${pkgs.pokeget-rs}/bin/pokeget random --hide-name
        '';
      };

      # gitignore
      gitignore = {
        description = "Create a .gitignore file";
        body = ''
          curl -sL https://www.gitignore.io/api/$argv
        '';
      };
    };
  };
}
