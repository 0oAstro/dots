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
      "--preview-window=:hidden"
      "--info=inline"

      # light theme
      "--color=light,bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39"
      "--color=light,fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78"
      "--color=light,marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39"
      "--color=light,selected-bg:#bcc0cc"

      # dark theme
      "--color=dark,bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284"
      "--color=dark,fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf"
      "--color=dark,marker:#babbf1,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284"
      "--color=dark,selected-bg:#51576d"

      "--preview 'bash -c \\'([[ -f {} ]] && (${pkgs.bat}/bin/bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200\\''"
    ];
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --exclude '.jj' '.git' --exclude '.pnpm-store' --exclude 'node_modules'";
    historyWidgetOptions = ["--sort"];
  };
}
