# zdots

My `$ZDOTDIR` dotfiles — zsh config powered by [antidote](https://github.com/mattmc3/antidote).

Inspired by [mattmc3/zdotdir](https://github.com/mattmc3/zdotdir).

## Setup

```zsh
# 1. Clone
export ZDOTDIR=~/.config/zsh
git clone git@github.com:0oAstro/zdots.git $ZDOTDIR

# 2. Bootstrap .zshenv (so zsh finds ZDOTDIR)
cat << 'EOF' >| ~/.zshenv
export ZDOTDIR=~/.config/zsh
[[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv
EOF

# 3. Reload
exec zsh
```

## Structure

```
~/.config/zsh/
├── .zshrc              # interactive shell entry point
├── .zshenv             # always-sourced env
├── .zprofile           # login shell
├── .zsh_plugins.txt    # antidote plugin manifest
├── .zsh_plugins.zsh    # generated plugin loader
├── .p10k.zsh           # powerlevel10k config
├── .zstyles            # zstyle settings
├── conf.d/             # modular config snippets
├── functions/          # custom autoloaded functions
├── lib/                # antidote bootstrap
└── .antidote/          # plugin cache (gitignored)
```

## Plugins

- [powerlevel10k](https://github.com/romkatv/powerlevel10k) — prompt
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
- [forgit](https://github.com/wfxr/forgit) — interactive git + fzf
- [ez-compinit](https://github.com/mattmc3/ez-compinit) — fast compinit
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [zsh-autopair](https://github.com/hlissner/zsh-autopair)
- [zsh-no-ps2](https://github.com/romkatv/zsh-no-ps2)

## Secrets

API keys and tokens live in the macOS Keychain, cached to `$XDG_CACHE_HOME/zsh/secrets-cache.zsh` on first shell load. See `conf.d/secrets.zsh` for the setup script (gitignored — never committed).
