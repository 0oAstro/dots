# dots

One repo for every machine. [Ansible](ansible/) runs everything: the system layer (Homebrew, macOS settings, packages, firewall, systemd units, Docker stacks, login shell) and then [chezmoi](https://chezmoi.io), which owns the home directory: zsh, git, the agent harnesses, the fonts, and the tool list. The zsh config came from `0oAstro/zdots` with its history.

## Modules

Every feature is a module: one folder, `modules/<name>/`. Its `module.yml` says which hosts get it and what it sets; Ansible and chezmoi both read it. To give a host a feature, add the host to that file. To add a feature, add a folder.

```yaml
# modules/berkeley_mono/module.yml
berkeley_mono:
  hosts: {thunderchief: }       # or children: {macs: } for every Mac
  vars:
    chezmoi:
      fonts: [berkeley_mono]
```

| In the folder | Read by | Does |
| --- | --- | --- |
| `module.yml`: `hosts:` or `children:` | Ansible (it is an inventory file) | Which hosts are in the module. `children: {macs: }` means every host in the `macs` module |
| `module.yml`: `vars:` | Ansible roles | Lists named `<kind>_<module>` (`macos_defaults_look`, `launchd_services_games`); see System layer |
| `module.yml`: `vars: chezmoi: home: [...]` | chezmoi | Home paths applied only on hosts in the module |
| `module.yml`: `vars: chezmoi: remove: [...]` | chezmoi | Home paths deleted on hosts not in it |
| `module.yml`: `vars: chezmoi: fonts: [...]` | chezmoi | Branches of the private `0oAstro/fonts` repo, cloned into `~/Library/Fonts/<branch>` |
| `module.yml`: `vars: chezmoi: harness: true` | chezmoi | The module is an agent harness (`claude`, `pi`, `prime`, `cursor`, `droid`) |
| `Brewfile` | the homebrew role | Apps for every Mac in the module |
| `overlay/` | the overlay role (Linux) | Files copied onto `/` |
| `user_units/` | the user_units role (Linux) | systemd user units for the login user |

Kinds are modules too: `macs`, `linux`, `servers` (always-on), `desktops`. So are hosts: `host_<name>` holds a host's own apps and files, and its inline host vars (`screenshot_dir`, `pmset_*`) override every other module. `modules/all/` holds the settings every host gets.

```sh
mise run modules                # every host and its modules
mise run modules thunderchief   # one host
```

## Set up a machine

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/0oAstro/dots/master/install.sh)"
```

That is for the machine you are sitting at. `install.sh` bootstraps only what Ansible cannot do unattended: it installs [mise](https://mise.jdx.dev), logs in to GitHub, asks for the age key, runs Homebrew's installer on a Mac, and clones this repo. It then runs the playbook for this host. A host that no module lists gets `macs` or `desktops` for that run (`DOTS_GROUP` overrides); add it to `modules/macs/module.yml` (or `desktops`) and a `host_<name>` module, and commit.

For a server, add it to `modules/servers/module.yml` and provision it from another machine. The playbook installs mise there, copies the age key and a GitHub login from the controller, clones this repo, and applies chezmoi.

The playbook writes the host's modules into chezmoi's config (`chezmoi init --promptString modules=...`), so nothing prompts. chezmoi derives `server` (the `servers` module) and `harnesses` from them. The host running the playbook manages itself locally and the rest over SSH:

```sh
mise run provision -- --check --diff   # dry run on every host
mise run provision                      # apply; ends with chezmoi on each host
mise run provision -- --limit aardvark  # one host
```

## System layer (Ansible)

Roles are generic; groups and hosts hold the data. A second run reports `changed=0`.

| Where | What |
| --- | --- |
| `modules/macs/` | What every Mac is: Homebrew taps to drop, application firewall, the `dev.dots.brew-upgrade` launchd agent, the base Brewfile |
| `modules/<module>/` | One feature each. `look`, `input`, `finder`, `perf`, `vendor_updaters_off` and `ai_off` take every Mac (`children: {macs: }`); `apps_dev`, `apps_comms`, `apps_media`, `games`, `google_drive`, `dropbox` and the fonts list their hosts |
| `modules/<module>/Brewfile` | Homebrew: a Mac gets the Brewfile of every module it is in. Together they are the whole truth: anything installed but unlisted is uninstalled |
| `modules/linux/`, `servers/`, `desktops/` | Base packages, Tailscale (official repo), Claude Remote Control and the Rex server on servers |
| `modules/host_<host>/` | That host's personal choices as host vars (`screenshot_dir`, `macos_appearance`, `dock_tilesize`, `pmset_*`), packages, enabled units, firewalld zones, Docker stacks, its Brewfile |
| `modules/<module>/overlay/` | Files copied onto `/` (`linux`, `servers`, `host_aardvark`). Two modules may not write the same path. sysctl, exports, sshd, firewalld direct rules and systemd units reload when they change |

Lists named `packages_*`, `systemd_enabled_*`, `systemd_masked_*`, `macos_defaults_*`, `launchd_agents_*`, `launchd_services_*`, `launchd_daemons_absent_*`, `login_items_*` and `home_links_*` merge across modules, so each module adds its own; name them after the module (`macos_defaults_games`, `launchd_services_thunderchief`). A defaults key or launchd label set by two modules fails the run. Login items are exclusive: an app that no layer lists is removed. Firewalld services, ports and rich rules are exclusive too, so hand-added ones get removed.

aardvark's `/opt/docker` is the private repo `0oAstro/infra` (its `tofu/` holds the OpenTofu edge config). The `docker_stacks` role fast-forwards it, writes its secrets, installs the units the stacks own, creates the shared networks, and runs `docker compose up` for every stack without a `DISABLED` file. Secrets there are age-encrypted copies (`sealed/`, same key as this repo) listed in `secrets.yml`. The `secrets` role creates missing ones and fails, without writing, when a live secret differs from its copy: run `bin/seal` there to keep the live one, or pass `-e secrets_take_sealed=true` to restore the copy.

## Change something

```sh
chezmoi edit --apply ~/.config/git/config   # edit the repo copy, then apply it
chezmoi re-add ~/.config/rex/init.lua       # or copy an in-place edit back
chezmoi cd                                  # commit and push from here
chezmoi update                              # on the other machines
```

| To change | Edit |
| --- | --- |
| Tools | `~/.config/mise/conf.d/core.toml` (both OSes), `macos.toml`, `linux.toml`, `ai.toml` |
| macOS apps | `modules/macs/Brewfile` (every Mac), `modules/<module>/Brewfile`, or `modules/host_<host>/Brewfile` |
| A host's modules | the `hosts:` of each `modules/<module>/module.yml`, then `mise run provision -- --limit <host>` |
| A new harness | `conf.d/harness-<name>.toml` and `modules/<name>/module.yml` with `harness: true` and its `home:` paths |
| A paid font | a branch of `0oAstro/fonts` (its README), then `modules/<family>/module.yml` with `fonts: [<family>]` |
| Machine settings, packages, firewall, units | `modules/` and the roles in `ansible/roles/` (see System layer) |
| API keys | `edit-secrets` (re-encrypts and applies) |
| SSH hosts | `chezmoi edit ~/.ssh/config.d/$(uname -n)` |

Tools track `latest` (or `lts`), so there is nothing to bump. mise holds new releases for 24 hours, except for the agent CLIs. `mise use -g` writes to `~/.config/mise/config.toml`; move anything worth keeping into `conf.d`.

## What goes where

| | Files |
| --- | --- |
| every machine | zsh, git, tmux, bat, ripgrep, glow, dtop, btop, Rex init.lua; `conf.d/core.toml` |
| any harness | pstack, agent-browser; `conf.d/ai.toml` |
| a harness module | that harness's CLI in `conf.d/harness-<name>.toml` and its settings (`claude`, `pi`, `prime`, `cursor`) |
| macOS | lazysql; `conf.d/macos.toml` |
| Linux | `conf.d/linux.toml` |
| `input` module | Karabiner |
| a font module | that family in `~/Library/Fonts/<family>` |

`home/.chezmoiignore` holds the OS rules; module rules come from each module's `chezmoi: home:`. Ansible copies `modules/<module>/user_units/` into `~/.config/systemd/user/` (claude-rc and rex-server for `servers`; the AlgoChat timers for `host_aardvark`).

Fonts need the GitHub login (`gh`, through mise) to clone the private repo. On a fresh machine that login's shim appears during the first apply, so fonts arrive on the second.

## Secrets

Secrets are age-encrypted in the repo (`encrypted_*.age`), using chezmoi's built-in age. Every machine uses the same key, `~/.config/age/keys.txt`. Keep a copy outside the repo, for example in Bitwarden. Without the key, chezmoi skips the encrypted files and applies everything else. To add the key later, save it with mode `600` and run `chezmoi apply`.

chezmoi decrypts the API keys to `~/.config/secrets/agents.env` (mode `600`, `NAME=value` lines). zsh exports only the allowlist in `.zshenv` (the Azure pair and `FIRECRAWL_API_KEY`); `secret NAME` exports another key into the current shell. systemd units on aardvark read the file with `EnvironmentFile=`. Each host's SSH config goes to `~/.ssh/config.d/<host>`.

## Files the apps also write

Claude Code and Pi rewrite their own settings. `modify_` templates merge the keys kept in `home/.chezmoitemplates/` into the live file. Keys the app owns survive: Pi's last-seen version, a model picked with `/model`. `btop.conf` is written only when missing, because btop saves its settings on exit.

Symlinks that must survive tool upgrades point at mise's `latest` folder: the Docker CLI plugins.

## Check the repo

```sh
mise run fmt     # format every shell script (shfmt, templates included)
mise run check   # format check, lint, secret scan, playbook syntax, render every profile, start zsh
```

CI runs the same checks on Linux and macOS.
