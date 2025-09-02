{ ... }:
let
  onePassPath = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in
{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        AddKeysToAgent yes
        UseKeychain yes
        IdentityAgent '${onePassPath}'
        SetEnv TERM=xterm-256color
    '';
  };
}
