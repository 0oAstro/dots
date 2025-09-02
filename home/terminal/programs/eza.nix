{ ... }:
{
  programs.eza = {
    enable = true;
    git = true;
    enableFishIntegration = true;
    extraOptions = [ "--group-directories-first" "--header" ];
    icons = "auto";
    colors = "auto";
  };
}
