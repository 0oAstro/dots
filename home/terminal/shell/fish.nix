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
      # name: 'Catppuccin Latte'
      # url: 'https://github.com/catppuccin/fish'
      # preferred_background: eff1f5

      set -g fish_color_normal 4c4f69
      set -g fish_color_command 1e66f5
      set -g fish_color_param dd7878
      set -g fish_color_keyword d20f39
      set -g fish_color_quote 40a02b
      set -g fish_color_redirection ea76cb
      set -g fish_color_end fe640b
      set -g fish_color_comment 8c8fa1
      set -g fish_color_error d20f39
      set -g fish_color_gray 9ca0b0
      set -g fish_color_selection --background=ccd0da
      set -g fish_color_search_match --background=ccd0da
      set -g fish_color_option 40a02b
      set -g fish_color_operator ea76cb
      set -g fish_color_escape e64553
      set -g fish_color_autosuggestion 9ca0b0
      set -g fish_color_cancel d20f39
      set -g fish_color_cwd df8e1d
      set -g fish_color_user 179299
      set -g fish_color_host 1e66f5
      set -g fish_color_host_remote 40a02b
      set -g fish_color_status d20f39
      set -g fish_pager_color_progress 9ca0b0
      set -g fish_pager_color_prefix ea76cb
      set -g fish_pager_color_completion 4c4f69
      set -g fish_pager_color_description 9ca0b0

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

      lec = {
        description = "opens lecs one by one";
        body = ''
          set start $argv[1]
          set end $argv[2]

          for i in (seq $start $end)
              echo "Opening Lecture $i..."
              open -a Preview "Lecture $i slides.pdf"

              # send fullscreen
              osascript -e 'tell application "Preview" to activate' \
                        -e 'tell application "System Events" to keystroke "f" using {control down, command down}'

              echo "Waiting for you to close Lecture $i (Cmd+W)..."
              while true
                  set win_count (osascript -e 'tell application "Preview" to count windows')
                  if test $win_count -eq 0
                      break
                  end
                  sleep 1
              end
          end
        '';
      }
    };
  };
}
