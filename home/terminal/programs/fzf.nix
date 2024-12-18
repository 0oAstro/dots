{pkgs, ...}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "${pkgs.fd}/bin/fd --hidden --type f --exclude '.jj' '.git' --exclude '.pnpm-store' --exclude 'node_modules'";
    changeDirWidgetOptions = [
      "--preview '${pkgs.eza}/bin/eza --icons --git --color always -T -L 3 {} | head -200'"
      "--exact"
    ];
    defaultOptions = [
      "--prompt='~ '"
      "--layout=reverse"
      "--multi"
      "--sort"
      "--bind '?:toggle-preview'"
      "--bind 'ctrl-a:select-all'"
      "--bind 'ctrl-e:execute(echo {+} | xargs -o nvim)'"
      "--height=80%"
      "--info=inline"
      "--ansi"
      "--preview='bat --color=always {}'"
    ];
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --exclude '.jj' '.git' --exclude '.pnpm-store' --exclude 'node_modules'";
    historyWidgetOptions = ["--sort"];
  };
}
