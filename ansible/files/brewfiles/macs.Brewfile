# Every Mac: the base apps and the few formulae mise can't provide. CLI tools
# belong in ~/.config/mise/conf.d. The homebrew role concatenates
# <group>.Brewfile for each inventory group the host is in, then
# <host>.Brewfile; anything installed but listed in none gets uninstalled,
# taps included.

tap "abue-ammar/tinycast", trusted: true
tap "henrygd/beszel"

brew "btop"
brew "gcc"
brew "mas"  # App Store apps; needs an App Store sign-in
brew "mole"  # deep clean and optimize the Mac
brew "zsh"

# Beszel agent, reporting to beszel.shau.me on aardvark. Env: ~/.config/beszel.
# macmon (GPU) and smartmontools (S.M.A.R.T.) must be on the service PATH.
brew "henrygd/beszel/beszel-agent", trusted: true, restart_service: :changed
brew "macmon"
brew "smartmontools"

cask "ghostty"
cask "abue-ammar/tinycast/tinycast"  # launcher, hotkeys, clipboard history
cask "tailscale-app"
cask "rustdesk"
cask "blip"
cask "helium-browser"
cask "notion"
cask "obsidian"

mas "Bitwarden", id: 1352778147
mas "uBlock Origin Lite", id: 6745342698
mas "Numbers", id: 361304891
