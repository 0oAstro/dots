{
  programs.starship = {
    enable = true;
    settings = {
      format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration$line_break$python$character";

      directory.style = "blue";

      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vicmd_symbol = "[❮](green)";
      };

      git_branch = {
        always_show_remote = true;
        ignore_branches = [
          "master"
          "main"
        ];
      };

      git_state = {
        format = "\([$state( $progress_current of $progress_total)]($style)\) ";
      };

      git_metrics = {
        disabled = false;
        format = "([ $added]($added_style) )([ $deleted]($deleted_style) )";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };

      aws = {
        symbol = "  ";
      };

      buf = {
        symbol = " ";
      };

      c = {
        symbol = " ";
      };

      conda = {
        symbol = " ";
      };

      dart = {
        symbol = " ";
      };

      directory = {
        read_only = " ";
      };

      docker_context = {
        symbol = " ";
      };

      elixir = {
        symbol = " ";
      };

      elm = {
        symbol = " ";
      };

      git_branch = {
        symbol = " ";
      };

      golang = {
        symbol = " ";
      };

      haskell = {
        symbol = " ";
      };

      hg_branch = {
        symbol = " ";
      };

      java = {
        symbol = " ";
      };

      julia = {
        symbol = " ";
      };

      lua = {
        symbol = " ";
      };

      memory_usage = {
        symbol = " ";
      };

      nim = {
        symbol = " ";
      };

      nix_shell = {
        symbol = " ";
      };

      nodejs = {
        symbol = " ";
      };

      package = {
        symbol = " ";
      };

      python = {
        symbol = " ";
        format = "[$virtualenv]($style) ";
        style = "bright-black";
      };

      rlang = {
        symbol = "ﳒ ";
      };

      ruby = {
        symbol = " ";
      };

      rust = {
        symbol = " ";
      };

      scala = {
        symbol = " ";
      };

      spack = {
        symbol = "🅢 ";
      };
    };
  };
}
