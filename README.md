# Wagounix

A declarative macOS system configuration using [nix-darwin](https://github.com/LnL7/nix-darwin) and [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## Overview

This repository contains a complete, reproducible macOS system configuration that manages:

- System packages and tools
- Homebrew packages and casks
- macOS UI/UX settings
- Fonts and system fonts
- Security settings
- User configuration

## Repository Structure

```text
.
├── core.nix              # Core system configuration (nix settings, security, users)
├── packages.nix          # System packages and fonts
├── homebrew.nix          # Homebrew packages, casks, and taps
├── icons.nix             # macOS custom icons
├── flake.nix             # Flake configuration and inputs
├── flake.lock            # Locked dependency versions (auto-generated)
├── .gitignore            # Git ignore rules
├── settings/             # macOS UI/UX settings
│   ├── control-center.nix
│   ├── dock.nix
│   ├── finder.nix
│   ├── global-domain.nix
│   ├── magic-mouse.nix
│   ├── menu-clock.nix
│   ├── screen-capture.nix
│   ├── screen-saver.nix
│   ├── software-update.nix
│   ├── spaces.nix
│   └── trackpad.nix
├── users/                # User-specific configurations (archived)
└── icons/                # Custom icon sets
```

## Key Features

- **Declarative System**: Everything is defined in Nix, ensuring reproducibility
- **Flake-based**: Uses modern Nix Flakes for dependency management
- **Homebrew Integration**: Manages both Nix packages and Homebrew formulae/casks
- **macOS Settings**: Configures system UI/UX preferences
- **Catppuccin Theme**: System theme using Catppuccin Mocha flavor
- **Rolling Updates**: Uses `nixpkgs-unstable` for automatic latest package access

## Installation

### Prerequisites

- macOS with Nix installed
- nix-darwin
- Flake support enabled

### Setup

```bash
# Clone or navigate to your config directory
cd ~/.config/wagounix

# Build and activate the configuration
darwin-rebuild switch --flake .#sap
```

## Updating Dependencies

To update Nix flake inputs to their latest versions:

```bash
nix flake update
```

This updates `flake.lock` without requiring manual edits to `flake.nix`.

## Configuration Files

### core.nix

System core settings:

- Nix settings and experimental features
- System version and primary user
- Security settings (TouchID for sudo)
- User definitions
- Catppuccin theme configuration

### packages.nix

Package management:

- System packages (CLI tools, development tools, applications)
- Nix package configuration
- Fonts installation

### homebrew.nix

Homebrew configuration:

- Homebrew taps (repositories)
- Formulae (command-line tools)
- Casks (GUI applications)
- Mac App Store applications

### settings

macOS system preferences:

- **dock.nix** - Dock configuration
- **finder.nix** - Finder preferences
- **global-domain.nix** - Global system defaults
- **screen-capture.nix** - Screenshot preferences
- **trackpad.nix** - Trackpad settings
- And more macOS-specific UI settings

## Author

Created for SAP macOS system management
