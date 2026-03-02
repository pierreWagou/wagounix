# ❄️ Wagounix

A declarative macOS system configuration using [nix-darwin](https://github.com/LnL7/nix-darwin) and [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## Overview

This repository contains a complete, reproducible macOS system configuration that manages:

- 📦 System packages and tools
- 🍺 Homebrew packages and casks
- 🖥️ macOS UI/UX settings
- 🔤 Fonts and system fonts
- 🔒 Security settings
- 👤 User configuration

## Repository Structure

### Root Configuration Files

| 📄 File | Purpose |
| ------ | --------- |
| `core.nix` | System core settings, security, and user configuration |
| `packages.nix` | System packages, CLI tools, and fonts |
| `homebrew.nix` | Homebrew formulae, casks, and tap repositories |
| `icons.nix` | Custom macOS icon configuration |
| `flake.nix` | Nix Flake inputs and system outputs |
| `flake.lock` | Locked dependency versions (auto-generated) |
| `.gitignore` | Git ignore rules for Nix projects |

### 🖥️ macOS System Settings (`settings/`)

| File | Purpose |
| ------ | --------- |
| `control-center.nix` | Control Center preferences |
| `dock.nix` | Dock appearance and behavior |
| `finder.nix` | Finder preferences |
| `global-domain.nix` | Global system defaults |
| `magic-mouse.nix` | Magic Mouse settings |
| `menu-clock.nix` | Menu bar clock configuration |
| `screen-capture.nix` | Screenshot preferences |
| `screen-saver.nix` | Screen saver settings |
| `software-update.nix` | Software update behavior |
| `spaces.nix` | Spaces and mission control |
| `trackpad.nix` | Trackpad settings |

### 📂 Other Directories

| Directory | Purpose |
| ----------- | --------- |
| `icons/` | 🎨 Custom icon sets |
| `users/` | 👤 User-specific configurations (archived) |

## ✨ Key Features

- 📝 **Declarative System**: Everything is defined in Nix, ensuring reproducibility
- 🔗 **Flake-based**: Uses modern Nix Flakes for dependency management
- 🍺 **Homebrew Integration**: Manages both Nix packages and Homebrew formulae/casks
- 🖱️ **macOS Settings**: Configures system UI/UX preferences
- 🎨 **Catppuccin Theme**: System theme using Catppuccin Mocha flavor
- 🔄 **Rolling Updates**: Uses `nixpkgs-unstable` for automatic latest package access

## 📦 Installation

### Prerequisites

- 🍎 macOS (Intel or Apple Silicon)
- 🔧 Nix (will be installed as first step)
- 📦 nix-darwin (installed automatically)
- ⚡ Flake support enabled (enabled during Nix setup)

### Bootstrap on a Fresh Machine

On a brand new machine where git isn't installed, follow these steps:

```bash
# 1. Install Nix (if not already installed)
curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh

# 2. Clone the wagounix repository
nix-shell -p git --run "git --version"
nix-shell -p git --run "git clone https://github.com/pierreWagou/wagounix.git ~/.config/wagounix"

# 3. Bootstrap nix-darwin and activate the configuration
cd ~/.config/wagounix
nix-shell -p nix-darwin --run "darwin-rebuild switch --flake .#sap"
```

### Rebuild system

Once bootstrapped, you can now use the flake to rebuild the system with this command:

```bash
darwin-rebuild switch --flake ~/.config/wagounix#sap
```

### Update Dependencies

To update Nix flake inputs to their latest versions:

```bash
nix flake update
```

This updates `flake.lock` without requiring manual edits to `flake.nix`.

## ⚙️ Configuration Files

### 🔧 core.nix

System core settings:

- Nix settings and experimental features
- System version and primary user
- Security settings (TouchID for sudo)
- User definitions
- Catppuccin theme configuration

### 📦 packages.nix

Package management:

- System packages (CLI tools, development tools, applications)
- Nix package configuration
- Fonts installation

### 🍺 homebrew.nix

Homebrew configuration:

- Homebrew taps (repositories)
- Formulae (command-line tools)
- Casks (GUI applications)
- Mac App Store applications

### 🎨 settings

macOS system preferences:

- **dock.nix** - 🚀 Dock configuration
- **finder.nix** - 📁 Finder preferences
- **global-domain.nix** - 🌍 Global system defaults
- **screen-capture.nix** - 📸 Screenshot preferences
- **trackpad.nix** - 👆 Trackpad settings
- And more macOS-specific UI settings
