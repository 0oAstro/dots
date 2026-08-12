# zdots

My `$ZDOTDIR` [dotfiles] directory, which contains my zsh configuration.

## My setup

I like my Zsh to behave like [Fish][fish], so there's a lot of features that will be very familiar to other Fish users. I also like the basic plugin structure of [Oh-My-Zsh][oh-my-zsh], even if I'm not as big of a fan of OMZ itself. This config is split into a few top-level areas:

- `config/core/` — shell options, history, key bindings, and `fpath`
- `config/plugins/` — antidote plugin wiring, fzf/zoxide, and zsh-patina theme toml
- `config/integrations/` — platform hooks (macOS/Linux), age-encrypted secrets, `spa` mosh helper, terminal tweaks
- `config/ui/` — aliases, clipboard helpers, fzf widgets, autosuggestions, editor keymaps
- `config/local/` — placeholder for machine-local overrides (secrets live in `.zshrc.local.age`)
- `lib/` — shared bootstrap (`antidote`, `path`, `compinit`, `prompt`, `recompile`)
- `functions/` — autoloaded command helpers on `$fpath`

Plugins are declared in `.zsh_plugins.txt` and bundled by [antidote][antidote] at startup (the `.antidote` checkout is gitignored and cloned on first use). Completion styles live in `.zstyles`; `lib/compinit.zsh` handles compdump freshness. `.zprofile` re-asserts `PATH` after macOS `path_helper` and runs a Linux-only `ssh-add` hook.

## Installation

Since this is my personal `$ZDOTDIR`, this installation procedure is mostly for my personal use.

Install this dotfiles repo to your `$ZDOTDIR`:

```zsh
# set the amazing ZDOTDIR variable
export ZDOTDIR=~/.config/zsh

# clone this repo
git clone git@github.com:0oAstro/zdots.git $ZDOTDIR

# change the root .zshenv file to use ZDOTDIR
cat << 'EOF' >| ~/.zshenv
export ZDOTDIR=~/.config/zsh
[[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv
EOF

# load zsh
zsh
```

## Performance

A snappy shell is very important. I regularly run [zsh-bench](https://github.com/romkatv/zsh-bench) to make sure my shell feels snappy (input lag, first-prompt latency, etc.).

For a blunt exit benchmark on this machine (Apple Silicon, [powerlevel10k][p10k] prompt, zsh 5.9):

```zsh
% hyperfine --warmup 10 'zsh -lic exit'
Benchmark 1: zsh -lic exit
  Time (mean ± σ):      59.9 ms ±   2.9 ms
  Range (min … max):    56.9 ms …  65.5 ms    20 runs
```

Numbers drift as plugins and integrations change — re-run the command above rather than trusting a README snapshot.

## Look-and-feel

### Fonts

Install [nerd fonts][nerd-fonts] via homebrew:

```zsh
brew tap homebrew/cask-fonts
brew install --cask font-meslo-lg-nerd-font
brew install --cask font-fira-code-nerd-font
brew install --cask font-hack-nerd-font
brew install --cask font-inconsolata-nerd-font
brew install --cask font-sauce-code-pro-nerd-font
```

### Color schemes

iTerm2 has some awesome [color schemes][iterm2-colors]. You can use them for more than
just iTerm2.

The whole shell palette is selected in `config/ui/theme.zsh`: light mode uses `kanagawa-lotus` and dark mode uses `kanagawa-dragon`. Palette files in `config/themes/shell/` theme Powerlevel10k, fzf, autosuggestions, and bat (through its ANSI theme); other ANSI-colored tools inherit Ghostty's matching `theme = dark:Kanagawa Dragon,light:Kanagawa Lotus` terminal palette. Change the two names at the top of `theme.zsh` to switch schemes while keeping older palette files available by name.

Syntax highlighting uses [zsh-patina](https://github.com/michel-kraemer/zsh-patina): the custom `kanagawa-lotus` theme in light mode and the official built-in `kanagawa` theme in dark mode. Shared plugin settings live in `config/plugins/zsh-patina.toml.in`; the older custom `kanagawa-vivid` theme remains available as an explicit `ZDOTS_PATINA_THEME=kanagawa-vivid` override.

On macOS, the current appearance is cached in `$XDG_CACHE_HOME/zsh/macos-appearance`. Normal startup uses only zsh builtins (well below the 3 ms budget); `/usr/bin/plutil` runs only when the preferences plist changes. Set `ZDOTS_APPEARANCE=light` or `dark` to override detection. Ghostty does not currently export the active half of a paired theme to its child shell.

`ZDOTS_APPEARANCE` is exported so SSH can forward the already-resolved `light`/`dark` value with `SendEnv ZDOTS_APPEARANCE`; servers opt in with `AcceptEnv ZDOTS_APPEARANCE`. This gives remote shells the same palette without running a platform appearance command remotely. Without a forwarded value, non-macOS shells safely default to dark.

## Resources

- [fish][fish]
- [antidote][antidote]
- [zephyr][zephyr]
- [zshzoo][zshzoo]
- [zsh_unplugged][zsh_unplugged]
- [prezto][prezto]
- [oh-my-zsh][oh-my-zsh]
- [supercharge your terminal with zsh][supercharge-zsh]
- [awesome zsh][awesome-zsh-plugins]

## Inspiration

This config is heavily inspired by [mattmc3/zdotdir][zdotdir], which is a masterfully crafted zsh configuration. Many of the performance tricks, structure decisions, and plugin choices are adapted from Matt's work. If you like this config, go star his repo.

[antidote]: https://github.com/mattmc3/antidote
[awesome-zsh-plugins]: https://github.com/unixorn/awesome-zsh-plugins
[fish]: https://fishshell.com
[dotfiles]: https://dotfiles.github.io/
[homebrew]: https://brew.sh
[iterm2-colors]: https://github.com/mbadolato/iTerm2-Color-Schemes
[nerd-fonts]: https://github.com/ryanoasis/nerd-fonts
[oh-my-zsh]: https://github.com/ohmyzsh/ohmyzsh
[p10k]: https://github.com/romkatv/powerlevel10k
[prezto]: https://github.com/sorin-ionescu/prezto
[supercharge-zsh]: https://blog.callstack.io/supercharge-your-terminal-with-zsh-8b369d689770
[zdotdir]: https://github.com/mattmc3/zdotdir
[zephyr]: https://github.com/zshzoo/zephyr
[zsh_unplugged]: https://github.com/mattmc3/zsh_unplugged
[zshzoo]: https://github.com/zshzoo/zshzoo
