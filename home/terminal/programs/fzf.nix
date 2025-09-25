{pkgs, ...}: {
  programs.skim = {
    enable = true;
    enableZshIntegration = false;
    enableFishIntegration = true;
    defaultCommand = "${pkgs.fd}/bin/fd --type f";
    changeDirWidgetOptions = [
      "--preview '${pkgs.eza}/bin/eza --icons --git --color always -T -L 3 {} | head -200'"
    ];
    defaultOptions = [
      "--prompt='~ '"
      "--layout=reverse"
      "--multi"
      "--height=40%"
      "--info=inline"
      "--border=top"
    ];
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d";
    historyWidgetOptions = ["--tac" "--sort"];
  };
}
