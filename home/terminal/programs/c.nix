{pkgs, ...}:
# c tooling
{
  home.packages = with pkgs; [
    libgccjit
  ];
}
