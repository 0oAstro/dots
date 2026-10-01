# dots

One [chezmoi](https://chezmoi.io) repo for every machine: zsh, git, the agent harnesses, and the tool list. The zsh config came from `0oAstro/zdots` with its history.

## Set up a machine

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/0oAstro/dots/master/install.sh)"
```

`install.sh` installs [mise](https://mise.jdx.dev), logs in to GitHub, and asks for the age key. It then runs `chezmoi init --apply 0oAstro/dots`. On a new host, chezmoi asks two questions: set up the coding agents (`ai`), and is this an always-on server (`server`)? Everything else follows the OS.

The first apply installs base packages or Homebrew, writes the configs, and runs `brew bundle` (macOS) and `mise install`. With `ai`, it also clones the pstack repos and starts the Bifrost proxy. To apply without prompts, pass `--promptDefaults` to `install.sh`.

## Change something

```sh
chezmoi edit --apply ~/.config/git/config   # edit the repo copy, then apply it
chezmoi re-add ~/.config/ghostty/config     # or copy an in-place edit back
chezmoi cd                                  # commit and push from here
chezmoi update                              # on the other machines
```

| To change | Edit |
| --- | --- |
| Tools | `~/.config/mise/conf.d/core.toml` (both OSes), `macos.toml`, `linux.toml`, `ai.toml` |
| macOS apps | `~/.config/homebrew/Brewfile` |
| API keys | `edit-secrets` (re-encrypts and applies) |
| SSH hosts | `chezmoi edit ~/.ssh/config.d/$(uname -n)` |

Tools track `latest` (or `lts`), so there is nothing to bump. mise holds new releases for 24 hours, except for the agent CLIs. `mise use -g` writes to `~/.config/mise/config.toml`; move anything worth keeping into `conf.d`.

## What goes where

| | Files |
| --- | --- |
| every machine | zsh, git, herdr, tmux, bat, ripgrep, glow, dtop, btop; `conf.d/core.toml` |
| `ai` | Claude Code, Codex, and Pi settings; pstack; bifrost-mitm; `conf.d/ai.toml` |
| `server` (with `ai`) | `claude-rc.service` (Claude Remote Control) |
| macOS | Brewfile, Ghostty, Karabiner, herdr launcher, lazysql, routerctl, the bifrost-mitm LaunchAgent; `conf.d/macos.toml` |
| Linux | bash, systemd user units; `conf.d/linux.toml` |

`home/.chezmoiignore` holds these rules.

## Secrets

Secrets are age-encrypted in the repo (`encrypted_*.age`), using chezmoi's built-in age. Every machine uses the same key, `~/.config/age/keys.txt`. Keep a copy outside the repo, for example in Bitwarden. Without the key, chezmoi skips the encrypted files and applies everything else. To add the key later, save it with mode `600` and run `chezmoi apply`.

chezmoi decrypts the API keys to `~/.config/zsh/.zshrc.local` (mode `600`), which zsh and bash both source. Each host's SSH config goes to `~/.ssh/config.d/<host>`.

## Files the apps also write

Claude Code, Codex, and Pi rewrite their own settings. `modify_` templates merge the keys kept in `home/.chezmoitemplates/` into the live file. Keys the app owns survive: Codex's trusted projects, Pi's last-seen version, a model picked with `/model`. `btop.conf` is written only when missing, because btop saves its settings on exit.

Symlinks that must survive tool upgrades point at mise's `latest` folder: the Docker CLI plugins and Codex's app-server binary.

## Check the repo

```sh
mise run check   # render every profile, parse every config, lint, scan for secrets
mise run smoke   # also start zsh in a scratch home
```

CI runs the same checks on Linux and macOS.
