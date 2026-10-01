<p align="center">
  <picture>
    <img src="https://github.com/TomhetArkitektur/artwork/blob/master/mooks/logo/logo.png" width="500px" alt="mooks logo">
  </picture>
  <br>
  <b>A minimal tmux configuration designed for well-structured modular setups</b>
</p>

# Rationale 

There is no 'sane default'.

Mooks was built as an alternative approach to existing setups like [oh-my-tmux](https://github.com/gpakosz/.tmux) and [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible).

Designed with modularity in mind, mooks provides a minimal base structure for customizations. Mooks has minimum own defaults (just tmux defaults itself) and thus avoids unnecessary complexity of bloated bash spaghetti.

This approach naturally lends itself to automation of setup and configuration. 

# Features

- **Strict modular design** – all parts of the config are split into files under `conf.d`
- **Minimal** – tmux.conf contains practically only `source-file` and `run-shell` commands
- **Automation-aware** – mooks configuration can be automated (e.g. via package manager) and installed in system-wide mode
- **TPM integration** – supports plugin management via [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- **Easily themeable** – built-in parser script for creating custom themes
- **Auto-updates** – auto-updates mooks from the git repo on startup and config reload
- **Clean code** – no obscure scripting inside tmux.conf

<p align="center">
  <picture>
    <img src="https://github.com/TomhetArkitektur/artwork/blob/master/mooks/screenshots/neofetch.png" width="500px" alt="mooks logo">
  </picture>
</p>

# Installation

Requirements: tested on `tmux` version 3.5a (probably would work with earlier versions), `git` (for auto-updates and plugin installation), `bash`. Also [nerd fonts](https://nerdfonts.com) and terminal [nord color palette](https://nordtheme.com/ports) for a default theme.

Mooks itself can be installed in any location, but user configs are forced to be in `~/.config/tmux` for compatibility reasons.

Clone repo:

```bash
git clone https://github.com/TomhetArkitektur/mooks.git ~/.config/tmux/mooks
```

Run init script:
```bash
~/.config/tmux/mooks/tools/init.sh
 ```

This will: 
- Create required directories: ~/.config/tmux/{conf.d,plugins,scripts,themes}
- Set up tmux.conf symlink and copy base config

Restart terminal app or reload tmux config (if already in a tmux session):

```bash
tmux source ~/.config/tmux/tmux.conf
```

## Uninstallation
```bash
rm -rvf ~/.config/tmux/mooks #Removes mooks only
# ONLY RUN IF NO EXISTING TMUX CONFIGURATION in respective location: rm ~/.config/tmux/
```

## NixOS

Coming soon

# Configuration

All configuration is done in files located inside `conf.d` directory

## Directory structure

Structure and file-naming is pretty self-describing:

    .
    ├── conf.d                  # User configuration files
    │   ├── auto_plugins.conf   # Auto-generated file listing plugins defined in @mooks-plugins
    │   ├── bindings.conf       # Keybingings
    │   ├── hooks.conf          # Hooks
    │   ├── main.conf           # Mooks config
    │   ├── options.conf        # Options
    │   └── plugins.conf        # Plugin list
    ├── scripts                 # Place for user scripts
    ├── themes                  # Place for user themes
    ├── tmux.conf

Refer to corresponding files in the repository for examples.

## Main.conf

The `main.conf` file itself includes descriptions of each configuration variable. 

You may want to change:

| Option                     | Default | Description                     |
|:---------------------------|:--------|:--------------------------------|
| @mooks-autoupdate-enable   | true    | Whether to enable mooks auto-updates from git, should be disabled in system-wide mode |
| @mooks-tpm-enable          | true    | Whether to enable tmux-plugin-manager, without it you should install plugins manually |
| @mooks-plugins             | ''      | Colon-separated string of plugin names (e.g. 'robhurring/tmux-uptime'). Mostly needed for plugin installation in themes, recommended way is to set plugins in plugins.conf for cleanliness |
| @mooks-theme               | nord    | Name of theme to use
| @mooks-theme-status-enable | true    | Whether to enable status.sh script for some tmux status automations and status lines parsing |

# Customization

Mooks is designed to serve as a bare foundation for modular tmux customization. Thus all customizations are just splited tmux customizations. Since mooks has minimal built-in customizations, it offers a clean tmux experience and encourages user to add functionality through plugins.

Mooks does not enforce any defaults that cannot be disabled or overridden. This is intentional. 

## Themes

> ~/.config/tmux/themes/$theme_name.conf

Built-in themes are stored in `mooks/themes` directory. Currently, only a [nord-inspired](https://www.nordtheme.com/) theme is included. Users can create their own themes and place them in `~/.config/tmux/themes`.

Mooks includes some configuration options for theming and status.sh script which parses those options to 'construct' tmux status line. Provided nord theme is a good self-described example of how to create custom themes.

Themes can specify plugins using a colon-separated list in the `@mooks-plugins` option.

## Plugins

> ~/.config/tmux/conf.d/plugins.conf

Automatic plugin management can be toggled using `@mooks-tpm-enable` option. For more details see [tmux-plugin-manager](https://github.com/tmux-plugins/tpm/) docs. Plugins are installed in `~/.config/tmux/plugins` directory.

No plugins are preconfigured, except those provided by themes (e.g., the Nord theme requires two plugins). 

Plugins must be declared in plugins.conf using TPM syntax: 

```bash
set -g @plugin 'MunifTanjim/tmux-suspend'
```

Plugins _can_ also be declared via `@mooks-plugins` option, but its primary purpose is to support plugins declared in themes. Sinse tpm does not source mooks theme files, plugins cannot be installed directly from themes using standard TPM syntax.

## Hooks

> ~/.config/tmux/conf.d/hooks.conf

Tmux provides numerous hooks, which you can view with:

```bash
tmux show-hooks    # session hooks
tmux show-hooks -g # global hooks
```

An example of hook creation can be found in `hooks.conf`

Detailed explanation of hooks may be found in this [article](https://devel.tech/tips/n/tMuXz2lj/the-power-of-tmux-hooks)

## Defaults

All keybindings are tmux default keybindings, except: `prefix` + <kbd>r</kbd> (reload tmux.conf).

### Tests

Currently tested only on Linux with tmux 3.5a. Compatibility testing on other operating systems and tmux versions will follow.

All shell scripts have been checked with ShellCheck. 
