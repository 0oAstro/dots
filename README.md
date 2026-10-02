# dots

One repo for every machine. [Ansible](ansible/) runs everything: the system layer (Homebrew, macOS settings, packages, firewall, systemd units, Docker stacks, login shell) and then [chezmoi](https://chezmoi.io), which owns the home directory: zsh, git, the agent harnesses, and the tool list. The zsh config came from `0oAstro/zdots` with its history.

## Set up a machine

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/0oAstro/dots/master/install.sh)"
```

That is for the machine you are sitting at. `install.sh` bootstraps only what Ansible cannot do unattended: it installs [mise](https://mise.jdx.dev), logs in to GitHub, asks for the age key, runs Homebrew's installer on a Mac, and clones this repo. It then runs the playbook for this host. A host missing from `ansible/inventory.yml` gets `macs` or `desktops` for that run (`DOTS_GROUP` overrides); add it to the inventory and commit.

For a server, add it to `servers` in `ansible/inventory.yml` and provision it from another machine. The playbook installs mise there, copies the age key and a GitHub login from the controller, clones this repo, and applies chezmoi.

The inventory decides chezmoi's two switches, `ai` (coding agents) and `server` (always-on host), through `chezmoi_data` in `ansible/group_vars/`. The playbook writes them into chezmoi's config, so nothing prompts. The host running the playbook manages itself locally and the rest over SSH:

```sh
mise run provision -- --check --diff   # dry run on every host
mise run provision                      # apply; ends with chezmoi on each host
mise run provision -- --limit aardvark  # one host
```

## System layer (Ansible)

Roles are generic; groups and hosts hold the data. A second run reports `changed=0`.

| Where | What |
| --- | --- |
| `group_vars/macs.yml` | macOS defaults, application firewall, the `dev.dots.brew-upgrade` launchd agent |
| `files/brewfiles/Brewfile` | Homebrew. The Brewfile is the whole truth: anything installed but unlisted is uninstalled |
| `group_vars/linux.yml`, `servers.yml`, `desktops.yml` | Base packages, Tailscale (official repo), Claude Remote Control on servers |
| `host_vars/<host>.yml` | That host's packages, enabled units, firewalld zones, Docker stacks |
| `files/overlays/<layer>/` | Files copied onto `/`, layered `linux`, then `servers` or `desktops`, then the host. sysctl, exports, sshd and systemd units reload when they change |

Lists named `packages_*` and `systemd_enabled_*` merge across groups and hosts. Firewalld services, ports and rich rules are exclusive, so hand-added ones get removed.

aardvark's `/opt/docker` is the private repo `0oAstro/aardvark-docker`. The `docker_stacks` role fast-forwards it, writes its secrets, installs the units the stacks own, creates the shared networks, and runs `docker compose up` for every stack without a `DISABLED` file. Secrets there are age-encrypted copies (`sealed/`, same key as this repo) listed in `secrets.yml`. The `secrets` role creates missing ones and fails, without writing, when a live secret differs from its copy: run `bin/seal` there to keep the live one, or pass `-e secrets_take_sealed=true` to restore the copy.

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
| macOS apps | `ansible/files/brewfiles/Brewfile` |
| Machine settings, packages, firewall, units | `ansible/` (see System layer) |
| API keys | `edit-secrets` (re-encrypts and applies) |
| SSH hosts | `chezmoi edit ~/.ssh/config.d/$(uname -n)` |

Tools track `latest` (or `lts`), so there is nothing to bump. mise holds new releases for 24 hours, except for the agent CLIs. `mise use -g` writes to `~/.config/mise/config.toml`; move anything worth keeping into `conf.d`.

## What goes where

| | Files |
| --- | --- |
| every machine | zsh, git, herdr, tmux, bat, ripgrep, glow, dtop, btop; `conf.d/core.toml` |
| `ai` | Claude Code, Codex, Pi, and Grok Build settings; pstack; `conf.d/ai.toml` |
| macOS | Ghostty, Karabiner, herdr launcher, lazysql, routerctl; `conf.d/macos.toml` |
| Linux | bash; `conf.d/linux.toml` |

`home/.chezmoiignore` holds these rules. Ansible copies `ansible/files/user_units/<layer>/` into `~/.config/systemd/user/` (claude-rc for `servers`; the AlgoChat timers and T3 drop-ins for aardvark).

## Secrets

Secrets are age-encrypted in the repo (`encrypted_*.age`), using chezmoi's built-in age. Every machine uses the same key, `~/.config/age/keys.txt`. Keep a copy outside the repo, for example in Bitwarden. Without the key, chezmoi skips the encrypted files and applies everything else. To add the key later, save it with mode `600` and run `chezmoi apply`.

chezmoi decrypts the API keys to `~/.config/zsh/.zshrc.local` (mode `600`), which zsh and bash both source. Each host's SSH config goes to `~/.ssh/config.d/<host>`.

## Files the apps also write

Claude Code, Codex, Pi, and Grok Build rewrite their own settings. `modify_` templates merge the keys kept in `home/.chezmoitemplates/` into the live file. Keys the app owns survive: Codex's trusted projects, Pi's last-seen version, a model picked with `/model`. `btop.conf` is written only when missing, because btop saves its settings on exit.

Symlinks that must survive tool upgrades point at mise's `latest` folder: the Docker CLI plugins and Codex's app-server binary.

## Check the repo

```sh
mise run fmt     # format every shell script (shfmt, templates included)
mise run check   # format check, lint, secret scan, playbook syntax, render every profile, start zsh
```

CI runs the same checks on Linux and macOS.
