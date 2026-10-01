# dots

One [chezmoi](https://chezmoi.io) repo for every machine: zsh, git, agent harnesses, terminal, and the tool list. It replaces `0oAstro/zdots`, whose history lives on under `home/dot_config/zsh`.

## Set up a machine

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/0oAstro/dots/master/install.sh)"
```

`install.sh` installs [mise](https://mise.jdx.dev), logs in to GitHub, asks for the age key, then runs `chezmoi init --apply 0oAstro/dots`. Known hosts (`aardvark`, `thunderchief`) get their modules without questions. Any other host is asked which modules to enable.

The first apply then:

1. installs zsh, git, and curl (Linux) or Homebrew (macOS),
2. writes every config file,
3. runs `brew bundle` (macOS with `gui`) and `mise install`,
4. clones the pstack repos and links their skills (`ai`),
5. starts Claude Remote Control as a systemd user unit (`ai` + `server`),
6. offers to make zsh the login shell.

To apply without prompts, for example in a container, pass `--promptDefaults` to `install.sh`.

## Change something

Edit the file where it lives, then copy the change into the repo:

```sh
chezmoi re-add ~/.config/ghostty/config     # plain files
chezmoi edit --apply ~/.config/git/config   # templates (.tmpl in the repo)
chezmoi cd                                  # then commit and push
```

On the other machines, run `chezmoi update`. Run `chezmoi diff` first to see what an apply would change.

| To change | Edit |
| --- | --- |
| API keys | `edit-secrets` (zsh function; re-encrypts and applies) |
| Tools | `~/.config/mise/conf.d/<module>.toml` via `chezmoi edit` |
| macOS apps | `~/.config/homebrew/Brewfile` |
| SSH hosts | `chezmoi edit ~/.ssh/config.d/$(uname -n)` |
| Modules for this machine | `chezmoi init` (asks again on unknown hosts), or edit `.chezmoi.toml.tmpl` |

`mise use -g tool` still writes to `~/.config/mise/config.toml`. Move anything worth keeping into a module file.

## Modules

`core` always applies: zsh, git, bash (Linux), tmux, zellij, herdr, bat, ripgrep, languages, and the CLI tools in `conf.d/10-core.toml`.

| Module | Adds |
| --- | --- |
| `ai` | Claude Code, Codex, and Pi configs; pstack; agent CLIs in `conf.d/20-ai.toml` |
| `cloud` | AWS, Azure, gcloud, Vercel, Neon, Firebase CLIs |
| `docker` | Docker CLI with buildx and compose; lazydocker config |
| `db` | psql, mysql; lazysql config (macOS) |
| `sync` | rclone, age, Bitwarden; Maestral and himalaya (Linux) |
| `ml` | Hugging Face, Kaggle, whisper.cpp |
| `media` | ffmpeg, yt-dlp, pget |
| `apple` | CocoaPods, SwiftFormat, SwiftLint, Tuist |
| `gui` | Ghostty, kitty, Karabiner, Zed, herdr launcher, Brewfile |
| `server` | Claude Remote Control unit, `termius-zmx` |

`home/.chezmoi.toml.tmpl` holds the host table. `home/.chezmoiignore` maps modules and operating systems to files.

## Secrets

Secrets are age-encrypted in the repo (`encrypted_*.age`) with chezmoi's built-in age. The key is `~/.config/age/keys.txt`. It is the same key on every machine. Keep a copy outside the repo, for example in Bitwarden.

Without the key, chezmoi skips the encrypted files and applies everything else. To add the key later, save it to `~/.config/age/keys.txt` with mode `600`, then run `chezmoi apply`.

On apply, chezmoi decrypts the API keys to `~/.config/zsh/.zshrc.local` (mode `600`). Both zsh and bash source that file. Per-host SSH config is decrypted to `~/.ssh/config.d/<host>`.

## Files the apps also write

Claude Code, Codex, and Pi rewrite their own settings files. `modify_` templates merge the keys this repo manages into the current file and keep the keys the app owns. Codex's trusted projects, Pi's last-seen version, and a model picked with `/model` survive an apply. The managed keys are in `home/.chezmoitemplates/`.

`btop.conf` is written only when missing, because btop saves its settings on exit.

## Check the repo

```sh
mise run check   # render every profile, parse every config, lint, scan for secrets
mise run smoke   # also start zsh in a scratch home
```

CI runs the same checks on Linux and macOS.
