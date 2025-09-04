{ pkgs, username, ... }:
{
  ## COLIMA
  launchd.user.agents."colima.default" = {
    script = "colima start --foreground --cpu 1 --memory 0.5 --disk 5";
    serviceConfig = {
      Label = "com.colima.default";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${username}/.colima/default/daemon/launchd.stdout.log";
      StandardErrorPath = "/Users/${username}/.colima/default/daemon/launchd.stderr.log";

      # not using launchd.agents.<name>.path because colima needs the system ones as well
      EnvironmentVariables = {
        HOME = "/Users/${username}";
        PATH = "${pkgs.colima}/bin:${pkgs.docker}/bin:${pkgs.curl}/bin:${pkgs.gnutar}/bin:${pkgs.coreutils}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };

      UserName = username;
    };
  };
}
