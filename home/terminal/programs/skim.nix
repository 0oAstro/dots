{ pkgs, ... }: {
  programs.skim = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      defaultCommand =
        "${pkgs.fd}/bin/fd --hidden --type f --exclude '.git' --exclude '.pnpm-store' --exclude 'node_modules'";
      changeDirWidgetOptions = [
        "--preview 'exa --icons --git --color always -T -L 3 {} | head -200'"
        "--exact"
      ];
      defaultOptions = [
        "--prompt='~ '"
        "--layout=reverse"
        "--multi"
        "--bind '?:toggle-preview'"
        "--bind 'ctrl-a:select-all'"
        "--bind 'ctrl-e:execute(echo {+} | xargs -o nvim)'"
        "--height=80%"
        "--preview-window=:hidden"
        "--inline-info"
        # auto change theme based on OS theme
        ''--color=$(defaults read -globalDomain AppleInterfaceStyle &> /dev/null && echo fg:#c6d0f5,bg:#303446,matched:#414559,matched_bg:#eebebe,current:#c6d0f5,current_bg:#51576d,current_match:#303446,current_match_bg:#f2d5cf,spinner:#a6d189,info:#ca9ee6,prompt:#8caaee,cursor:#e78284,selected:#ea999c,header:#81c8be,border:#737994 || echo fg:#4c4f69,bg:#eff1f5,matched:#ccd0da,matched_bg:#dd7878,current:#4c4f69,current_bg:#bcc0cc,current_match:#eff1f5,current_match_bg:#dc8a78,spinner:#40a02b,info:#8839ef,prompt:#1e66f5,cursor:#d20f39,selected:#e64553,header:#179299,border:#9ca0b0)''
        ''--preview "bash -c '([[ -f {} ]] && (${pkgs.bat}/bin/bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (${pkgs.tree}/bin/tree -C {} | less)) || echo {} 2> /dev/null | head -200'"''
      ];
      changeDirWidgetCommand =
        "${pkgs.fd}/bin/fd --type d --hidden --exclude '.git' --exclude '.pnpm-store' --exclude 'node_modules'";
    };
}
