# dots

One repo for every machine. [chezmoi](https://chezmoi.io) owns the home directory: zsh, git, the agent harnesses, and the tool list. [Ansible](ansible/) owns the system layer: Homebrew apps, and on servers the firewall, systemd units, sysctl, and sshd. The zsh config came from `0oAstro/zdots` with its history.

## Set up a machine

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/0oAstro/dots/master/install.sh)"
```

`install.sh` installs [mise](https://mise.jdx.dev), logs in to GitHub, and asks for the age key. It then runs `chezmoi init --apply 0oAstro/dots`. On a new host, chezmoi asks two questions: set up the coding agents (`ai`), and is this an always-on server (`server`)? Everything else follows the OS.

The first apply installs base packages or Homebrew, writes the configs, and runs `mise install`. With `ai`, it also clones the pstack repos. To apply without prompts, pass `--promptDefaults` to `install.sh`.

Then add the host to `ansible/inventory.yml` and run the system layer from the checkout (`chezmoi cd`):

```sh
mise run provision -- --check --diff   # dry run on every host
mise run provision                      # apply; ends with chezmoi on each host
mise run provision -- --limit aardvark  # one host
```

The playbook is idempotent: a second run reports `changed=0`. Firewall services, ports, and rich rules are exclusive, so hand-added ones get removed. Homebrew installs what the Brewfile lists, never removes anything, and reports installed packages the Brewfile does not mention.

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
| macOS apps | `ansible/roles/homebrew/files/Brewfile` |
| Server firewall, units, packages | `ansible/host_vars/<host>.yml`, `ansible/roles/server/files/` |
| API keys | `edit-secrets` (re-encrypts and applies) |
| SSH hosts | `chezmoi edit ~/.ssh/config.d/$(uname -n)` |

Tools track `latest` (or `lts`), so there is nothing to bump. mise holds new releases for 24 hours, except for the agent CLIs. `mise use -g` writes to `~/.config/mise/config.toml`; move anything worth keeping into `conf.d`.

## What goes where

| | Files |
| --- | --- |
| every machine | zsh, git, herdr, tmux, bat, ripgrep, glow, dtop, btop; `conf.d/core.toml` |
| `ai` | Claude Code, Codex, and Pi settings; pstack; `conf.d/ai.toml` |
| macOS | Ghostty, Karabiner, herdr launcher, lazysql, routerctl; `conf.d/macos.toml` |
| Linux | bash; `conf.d/linux.toml` |

`home/.chezmoiignore` holds these rules. Ansible's `servers` group gets `claude-rc.service` (Claude Remote Control) as a user unit.

## Secrets

Secrets are age-encrypted in the repo (`encrypted_*.age`), using chezmoi's built-in age. Every machine uses the same key, `~/.config/age/keys.txt`. Keep a copy outside the repo, for example in Bitwarden. Without the key, chezmoi skips the encrypted files and applies everything else. To add the key later, save it with mode `600` and run `chezmoi apply`.

chezmoi decrypts the API keys to `~/.config/zsh/.zshrc.local` (mode `600`), which zsh and bash both source. Each host's SSH config goes to `~/.ssh/config.d/<host>`.

## Files the apps also write

Claude Code, Codex, and Pi rewrite their own settings. `modify_` templates merge the keys kept in `home/.chezmoitemplates/` into the live file. Keys the app owns survive: Codex's trusted projects, Pi's last-seen version, a model picked with `/model`. `btop.conf` is written only when missing, because btop saves its settings on exit.

Symlinks that must survive tool upgrades point at mise's `latest` folder: the Docker CLI plugins and Codex's app-server binary.

## Check the repo

```sh
mise run fmt     # format every shell script (shfmt, templates included)
mise run check   # format check, lint, secret scan, playbook syntax, render every profile, start zsh
```

CI runs the same checks on Linux and macOS.
