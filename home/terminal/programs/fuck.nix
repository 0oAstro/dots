{ ... }:
{
  programs.pay-respects = {
    enable = true;
    # enableFishIntegration = true;
    options = [
      "--alias"
      "f"
    ];
  };
}
