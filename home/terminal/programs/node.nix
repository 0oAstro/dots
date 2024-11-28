{pkgs, ...}:
# node tooling
{
  home.packages = with pkgs.nodePackages_latest; [
    nodejs
    pnpm
  ] // [ pkgs.bun ];
}
