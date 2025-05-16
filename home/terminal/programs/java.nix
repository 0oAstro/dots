{ pkgs, ... }:
# java tooling (for minecraft)
{
  home.packages = with pkgs; [
    jdk
  ];
}
