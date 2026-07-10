# zdots

My `$ZDOTDIR` [dotfiles] directory, which contains my zsh configuration.

## My setup

I like my Zsh to behave like [Fish][fish], so there's a lot of features that will be very familiar to other Fish users. I also like the basic plugin structure of [Oh-My-Zsh][oh-my-zsh], even if I'm not as big of a fan of OMZ itself. My Zsh has things like:

- A functions directory for my custom functions
- A completions directory for my custom completions
- A conf.d directory so that .zshrc isn't a cluttered mess
- My custom plugins in a separate `$ZSH_CUSTOM` project similar to how OMZ works

## Installation

Since this is my personal `$ZDOTDIR`, this installation procedure is mostly for my personal use.

Install this dotfiles repo to your `$ZDOTDIR`:

```zsh
# set the amazing ZDOTDIR variable
export ZDOTDIR=~/.config/zsh

# clone this repo
git clone --recursive git@github.com:0oAstro/zdots.git $ZDOTDIR

# change the root .zshenv file to use ZDOTDIR
cat << 'EOF' >| ~/.zshenv
export ZDOTDIR=~/.config/zsh
[[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv
EOF

# load zsh
zsh
```

## Performance

A snappy shell is very important. I regularly run [zsh-bench](https://github.com/romkatv/zsh-bench) to make sure my shell feels snappy.

The latest benchmark run shows that we load a new shell pretty fast.

```zsh
% # Apple M1 Air: starship prompt
% zsh-bench
==> benchmarking login shell of user shaurya ...
creates_tty=0
has_compsys=1
has_syntax_highlighting=1
has_autosuggestions=1
has_git_prompt=1
first_prompt_lag_ms=25.000
first_command_lag_ms=129.000
command_lag_ms=2.200
input_lag_ms=6.500
exit_time_ms=49.000
```

If you prefer a naive, completely meaningless Zsh 'exit' benchmark, I include that too for legacy reasons.

```zsh
% # Apple M1 Air
% hyperfine 'zsh -i -c exit'
Benchmark 1: zsh -i -c exit
  Time (mean ± σ):      43.3 ms ± 1.7 ms
  Range (min … max):    41.5 ms … 46.9 ms
```

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

I use Rosé Pine.

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
[prezto]: https://github.com/sorin-ionescu/prezto
[starship]: https://starship.rs
[supercharge-zsh]: https://blog.callstack.io/supercharge-your-terminal-with-zsh-8b369d689770
[zdotdir]: https://github.com/mattmc3/zdotdir
[zephyr]: https://github.com/zshzoo/zephyr
[zsh_unplugged]: https://github.com/mattmc3/zsh_unplugged
[zshzoo]: https://github.com/zshzoo/zshzoo
