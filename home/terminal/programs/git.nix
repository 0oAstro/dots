{
  config,
  pkgs,
  username,
  hostname,
  ...
}:
let
  cfg = config.programs.git;
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJfml6YGLlOvm7VICn5K/G05N6JkHVLtWtpDL7ejvlvB ${username}@${hostname}";
in
{
  home.packages = [ pkgs.gh ];

  programs.git = {
    enable = true;

    delta = {
      enable = true;
      options.dark = true;
    };

    aliases = {
      a = "add";
      b = "branch";
      c = "commit";
      ca = "commit --amend";
      cm = "commit -m";
      co = "checkout";
      d = "diff";
      ds = "diff --staged";
      p = "push";
      pf = "push --force-with-lease";
      pl = "pull";
      l = "log";
      r = "rebase";
      s = "status --short";
      ss = "status";
      forgor = "commit --amend --no-edit";
      graph = "log --all --decorate --graph --oneline";
      oops = "checkout --";
    };

    ignores = [
      "*~"
      "*.swp"
      "*result*"
      ".direnv"
      "node_modules"
      ".jj"
      "*.bin"
      "**/.DS_Store"
      "**/._.DS_Store"
    ];

    signing = {
      key = key;
      signByDefault = true;
    };

    extraConfig = {
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile =
          config.home.homeDirectory + "/" + config.xdg.configFile."git/allowed_signers".target;
      };

      gpg."ssh".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

      pull.rebase = true;

      init.defaultBranch = "main";
      push.autoSetupRemote = true;

      rebase = {
        autosquash = true;
        autostash = true;
      };

      commit = {
        verbose = true;
        gpgsign = true;
      };

      rerere.enabled = true;
      help.autocorrect = "prompt";

      diff.algorithm = "histogram";

      url."git@github.com:".insteadOf = "https://github.com/";

      merge.tool = "meld";
      branch.sort = "-committerdate";
    };

    userEmail = "79555780+0oAstro@users.noreply.github.com"; # private e-mail, mail scraping is a thing?
    userName = "0oAstro";
  };

  xdg.configFile."git/allowed_signers".text = ''
    ${cfg.userEmail} namespaces="git" ${key}
  '';
}
