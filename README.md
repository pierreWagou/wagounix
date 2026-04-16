# Wagounix

Declarative system configuration for macOS and NixOS using [nix-darwin](https://github.com/nix-darwin/nix-darwin), [NixOS](https://nixos.org/), and [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## Overview

This repository manages multiple machines across macOS and NixOS through a layered, reproducible configuration:

- **Cross-platform** — common packages and user config shared across macOS and NixOS
- **Platform modules** — darwin-specific (Homebrew, macOS settings, icons) and NixOS-specific (systemd, bootloader, services)
- **Role-based layers** — personal / work layers for macOS machines
- **Per-host overrides** — machine-specific config for each host
- **Pre-commit hooks** via [git-hooks.nix](https://github.com/cachix/git-hooks.nix)
- **CI** via GitHub Actions (lint + build all profiles)

## Repository Structure

```
wagounix/
├── flake.nix                # Inputs, darwinConfigurations, nixosConfigurations, checks, devShell
├── flake.lock               # Pinned dependency versions
├── packages.nix             # Common nix packages (all platforms)
├── fonts.nix                # Common fonts (all platforms)
├── users.nix                # Common user config (all platforms)
│
├── darwin/                  # macOS-specific modules
│   ├── default.nix          # Imports configuration, homebrew, icons, settings
│   ├── configuration.nix    # nix-darwin system config (stateVersion, PAM)
│   ├── homebrew.nix         # Homebrew brews, casks, taps
│   ├── icons.nix            # Custom macOS app icons
│   └── settings/            # macOS system defaults
│       ├── default.nix
│       ├── dock.nix
│       ├── finder.nix
│       └── ...
│
├── nixos/                   # NixOS-specific modules
│   ├── default.nix          # Imports configuration
│   └── configuration.nix    # NixOS system config (bootloader, networking, docker)
│
├── hosts/
│   ├── darwin/              # macOS hosts
│   │   ├── personal/        # Personal layer (dock, packages, homebrew)
│   │   │   ├── wagou/       # New personal Mac (aarch64-darwin)
│   │   │   └── wagou-old/   # Old Intel Mac (x86_64-darwin)
│   │   └── work/            # Work layer (dock, packages, homebrew)
│   │       ├── sap/         # SAP Mac — legacy, remove when returned
│   │       └── pro/         # New work Mac (aarch64-darwin)
│   └── nixos/               # NixOS hosts
│       └── homeserver/      # Home server (x86_64-linux)
│
└── icons/                   # .icns icon files
```

## Host Profiles

Each configuration loads modules in layers:

1. **Common** — `packages.nix`, `fonts.nix`, `users.nix` (cross-platform)
2. **Platform** — `darwin/` or `nixos/` (platform-specific)
3. **Layer** — `hosts/darwin/personal` or `hosts/darwin/work` (role-specific, macOS only)
4. **Host** — `hosts/<platform>/<layer>/<host>` (machine-specific)

### macOS (darwinConfigurations)

| Profile | System | Layer | Description |
|---------|--------|-------|-------------|
| `sap` | aarch64-darwin | work | SAP work Mac (legacy) |
| `wagou-old` | x86_64-darwin | personal | Old Intel Mac |
| `wagou` | aarch64-darwin | personal | New personal Mac |
| `pro` | aarch64-darwin | work | New work Mac |

### NixOS (nixosConfigurations)

| Profile | System | Description |
|---------|--------|-------------|
| `homeserver` | x86_64-linux | Home server (Docker, services) |

## Installation

### macOS — Bootstrap on a Fresh Machine

```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
sudo nix run nix-darwin -- switch --flake github:pierreWagou/wagounix#<profile>
```

### macOS — Rebuild

```bash
darwin-rebuild switch --flake ~/.config/wagounix#<profile>
```

### NixOS — Rebuild

```bash
sudo nixos-rebuild switch --flake ~/.config/wagounix#<profile>
```

### Update Dependencies

```bash
nix flake update
```

## Development

### Dev Shell

Git hooks auto-install when entering the project directory (via mise), or manually:

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

- **darwin-build** — builds all darwin profiles to verify correctness

### CI

GitHub Actions runs on every push to `main` and on PRs:

- **Lint** — nixfmt, statix, deadnix (macos-15)
- **Build darwin** — sap, wagou, pro (macos-15, parallel)
- **Build NixOS** — homeserver (ubuntu-latest)

### Flake Checks

```bash
nix flake check
```

Runs all checks plus builds all configurations.
