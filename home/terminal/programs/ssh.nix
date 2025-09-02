{ ... }:
let
  onePassPath = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "iitd" = {
        user = "ee1240486";
        host = "ssh1.iitd.ac.in";
        forwardAgent = true;
      };
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "confirm";
        compression = true;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = true;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "10m";
        identityAgent = "'${onePassPath}'";
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
