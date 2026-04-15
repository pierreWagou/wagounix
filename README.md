# Wagounix

A declarative macOS system configuration using [nix-darwin](https://github.com/nix-darwin/nix-darwin) and [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## Overview

This repository manages multiple macOS machines through a layered, reproducible configuration:

- Common packages and settings shared across all machines
- Role-based layers (personal / work) for apps and dock layout
- Per-host overrides for machine-specific needs
- macOS UI/UX settings configured declaratively
- Homebrew casks and Mac App Store apps
- Custom application icons
- Pre-commit hooks via [git-hooks.nix](https://github.com/cachix/git-hooks.nix)

## Repository Structure

```
wagounix/
├── flake.nix              # Inputs, darwinConfigurations, checks, devShell
├── flake.lock             # Pinned dependency versions
├── configuration.nix      # Core system config (users, PAM, settings import)
├── packages.nix           # Common nix packages (CLI tools, dev tools)
├── homebrew.nix           # Common Homebrew brews and casks
├── fonts.nix              # Fonts (Nerd Fonts)
├── icons.nix              # Custom macOS app icons
├── icons/                 # .icns icon files
├── settings/              # macOS system defaults
│   ├── default.nix        # Imports all settings modules
│   ├── dock.nix           # Dock behavior (autohide, persistent-others)
│   ├── finder.nix         # Finder preferences
│   ├── global-domain.nix  # Global defaults (dark mode, key repeat, etc.)
│   ├── keyboard.nix       # Key mapping, shortcut overrides
│   └── ...                # control-center, trackpad, menu-clock, etc.
└── hosts/
    ├── personal/           # Personal machine layer
    │   ├── default.nix     # Imports dock, packages, homebrew
    │   ├── dock.nix        # Personal dock apps
    │   ├── packages.nix    # Personal nix packages (android-tools, mas)
    │   ├── homebrew.nix    # Personal casks (Steam, Ankama, etc.) + masApps
    │   ├── wagou/          # New personal Mac (aarch64-darwin)
    │   │   ├── default.nix
    │   │   ├── variables.nix
    │   │   └── packages.nix
    │   └── wagou-old/      # Old Intel Mac (x86_64-darwin)
    │       ├── default.nix
    │       └── variables.nix
    └── work/               # Work machine layer
        ├── default.nix     # Imports dock, packages, homebrew
        ├── dock.nix        # Work dock apps (Outlook, Teams, etc.)
        ├── packages.nix    # Work nix packages (opencode)
        ├── homebrew.nix    # Work casks (placeholder)
        ├── sap/            # SAP Mac — legacy, remove when returned
        │   ├── default.nix
        │   ├── variables.nix
        │   ├── packages.nix
        │   └── homebrew.nix
        └── pro/            # New work Mac (aarch64-darwin)
            ├── default.nix
            └── variables.nix
```

## Host Profiles

Each `darwinConfiguration` in `flake.nix` loads:

1. **Common** — `configuration.nix`, `packages.nix`, `homebrew.nix`, `fonts.nix`, `icons.nix`
2. **Layer** — `hosts/personal` or `hosts/work` (role-specific packages, casks, dock)
3. **Host** — `hosts/<layer>/<host>` (machine-specific overrides)

| Profile | System | Layer | Description |
|---------|--------|-------|-------------|
| `sap` | aarch64-darwin | work | SAP work Mac (legacy) |
| `wagou-old` | x86_64-darwin | personal | Old Intel Mac |
| `wagou` | aarch64-darwin | personal | New personal Mac |
| `pro` | aarch64-darwin | work | New work Mac |

Each host provides a `variables.nix` with `username`, `restricted_app_dir`, and `enableRosetta`.

## Installation

### Bootstrap on a Fresh Machine

```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
sudo nix run nix-darwin -- switch --flake github:pierreWagou/wagounix#<profile>
```

### Rebuild

```bash
darwin-rebuild switch --flake ~/.config/wagounix#<profile>
```

### Update Dependencies

```bash
nix flake update
```

## Development

### Dev Shell

Enter the dev shell to get linting tools and auto-install git hooks:

```bash
nix develop
```

This provides `nixfmt`, `statix`, and `deadnix`, and installs pre-commit hooks automatically.

### Pre-commit Hooks

Managed by [git-hooks.nix](https://github.com/cachix/git-hooks.nix). On every commit:

- **nixfmt** — verifies Nix formatting
- **statix** — lints for anti-patterns
- **deadnix** — catches unused code

On push:

- **darwin-build** — builds all 4 profiles to verify correctness

### Flake Checks

```bash
nix flake check
```

Runs all the above checks plus builds all `darwinConfigurations`.
