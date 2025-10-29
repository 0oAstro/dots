# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix flake-based configuration for managing macOS systems using nix-darwin and home-manager. The repository contains a complete system configuration that manages both system-level settings and user-level packages with a modular structure.

## Key Architecture

The configuration is organized into several key areas:

- **System configuration** (`modules/`): Manages macOS system settings, nix-core configuration, apps, and services
- **Home manager** (`home/`): Manages user-level packages and configurations, organized by functionality
- **Terminal environment**: Comprehensive terminal setup with shells, emulators, and CLI tools
- **Development tools**: Editors, programming languages, and development utilities

## Common Commands

### System Management
```bash
# Build and switch to new system configuration
just darwin

# Build with debug/verbose output
just darwin-debug

# Update flake inputs
just update

# Format nix files
just fmt

# Clean build artifacts
just clean

# Garbage collection (remove generations older than 7 days)
just gc
```

### Nix Development
```bash
# Enter development shell
nix develop

# Format files manually
nix fmt

# Check system configuration
nix flake check
```

## Project Structure

### Core Files
- `flake.nix`: Main flake definition with inputs and outputs
- `Justfile`: Command runner for common operations
- `modules/`: System-level configuration modules
- `home/`: User-level home-manager configuration

### System Modules (`modules/`)
- `nix-core.nix`: Core nix configuration and settings
- `system.nix`: macOS system preferences and defaults
- `apps.nix`: System-level applications
- `services.nix`: System services
- `host-users.nix`: User configuration

### Home Configuration (`home/`)
- `default.nix`: Main home-manager entry point
- `terminal/`: Terminal environment (shells, emulators, CLI tools)
- `gui/`: GUI applications (currently commented out)

### Terminal Environment (`home/terminal/`)
- `shell/`: Shell configurations (zsh, fish, starship)
- `emulators/`: Terminal emulators (wezterm, ghostty)
- `programs/`: CLI utilities and tools organized by category

## Important Configuration Details

### System Settings
- Username: "shaurya" (defined in flake.nix:29)
- Hostname: "asuna" (defined in flake.nix:31, Justfile:4)
- System: "aarch64-darwin" (Apple Silicon Mac)

### Key Features
- Flakes enabled globally with experimental features
- Nix-index for package discovery
- Comprehensive terminal development environment
- Customized macOS defaults and dock configuration
- TouchID sudo authentication enabled

### Package Categories
- Development tools: Git, Docker, Node.js, C/C++ toolchain
- Terminal utilities: fzf, eza, bat, btop, zoxide
- Editors: Helix with language configurations
- Shells: Zsh with Oh My Zsh, Fish shell

## Development Notes

- This is a declarative configuration - all changes should be made through nix files
- The configuration uses home-manager for user package management
- System changes require `sudo` and use `darwin-rebuild switch`
- The repo includes pre-commit hooks for formatting (alejandra)
- GUI applications are currently disabled in home configuration (line 10 in home/default.nix)

## Host-specific Configuration

Before deploying, update the hostname variable:
- In `Justfile:4` - update the hostname string
- In `flake.nix:31` - update the hostname string
- The system is configured for Apple Silicon Macs (`aarch64-darwin`)