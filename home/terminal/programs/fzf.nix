{ pkgs, ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    defaultCommand = "${pkgs.fd}/bin/fd --hidden --type f --exclude '.jj' --exclude '.direnv' --exclude '.venv' --exclude '.git' --exclude 'logs'--exclude 'dist' --exclude 'build' --exclude 'node_modules' --exclude '.DS_Store' --exclude 'out' --exclude '.vscode' --exclude '.nuxt' --exclude '.next'";
    changeDirWidgetOptions = [
      "--preview '${pkgs.eza}/bin/eza --icons --git --color always -T -L 3 {} | head -200'"
      "--exact"
    ];
    defaultOptions = [
      "--prompt='~ '"
      "--layout=reverse"
      "--multi"
      "--height=80%"
      "--info=inline"
      "--border"

    ];
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --hidden --type f --exclude '.jj' --exclude '.direnv' --exclude '.venv' --exclude '.git' --exclude 'logs' --exclude 'dist' --exclude 'build' --exclude 'node_modules' --exclude '.DS_Store' --exclude 'out' --exclude '.vscode' --exclude '.nuxt' --exclude '.next' --exclude '.cache'";
    historyWidgetOptions = [ "--sort" ];
  };
}
