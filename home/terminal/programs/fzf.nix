{pkgs, ...}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "${pkgs.fd}/bin/fd --hidden --type f --exclude '.jj' --exclude '.direnv' --exclude '.venv' --exclude '.git' --exclude '.pnpm-store' --exclude 'node_modules'";
    changeDirWidgetOptions = [
      "--preview '${pkgs.eza}/bin/eza --icons --git --color always -T -L 3 {} | head -200'"
      "--exact"
    ];
    defaultOptions = [
      "--prompt='~ '"
      "--layout=reverse"
      "--multi"
      "--sort"
      "--bind 'ctrl-a:select-all'"
      "--bind 'ctrl-e:execute(echo {+} | xargs -o nvim)'"
      "--height=80%"
      "--info=inline"
      "--color=bg:-1,bg+:#363646,fg:-1,fg+:#8992a7,hl:#8992a7,hl+:#b98d7b"
      "--color=header:#87a987,info:#6A9589,pointer:#FF9E3B"
      "--color=marker:#FF9E3B,prompt:#DCA561,spinner:#6A9589"
    ];
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --exclude '.jj' --exclude '.direnv' --exclude '.venv' --exclude '.git' --exclude '.pnpm-store' --exclude 'node_modules'";
    historyWidgetOptions = [ "--sort" ];
  };
}
