<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=0:232741,100:5277C3&height=180&text=Wagounix&fontSize=50&fontColor=ffffff&desc=Declarative%20system%20config%20for%20macOS%20and%20NixOS&descSize=16&descAlignY=75&animation=fadeIn)

[![Check](https://github.com/pierreWagou/wagounix/actions/workflows/check.yml/badge.svg)](https://github.com/pierreWagou/wagounix/actions/workflows/check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Nix Flake](https://img.shields.io/badge/Nix-Flake-5277C3?logo=nixos&logoColor=white)
![nix-darwin](https://img.shields.io/badge/nix--darwin-macOS-000000?logo=apple&logoColor=white)
![NixOS](https://img.shields.io/badge/NixOS-Linux-5277C3?logo=nixos&logoColor=white)

</div>

## Overview

This repository manages multiple machines through a layered, reproducible configuration:

- **Cross-platform** — shared packages, fonts, and user config across macOS and NixOS
- **Platform modules** — Homebrew, macOS settings, and icons for darwin; bootloader, networking, and services for NixOS
- **Role-based layers** — personal and work layers for macOS machines
- **Per-host overrides** — machine-specific config where needed
- **Quality gates** — pre-commit hooks via [git-hooks.nix](https://github.com/cachix/git-hooks.nix) and CI via GitHub Actions

## Architecture

Each configuration is assembled from layered modules — common packages are shared across all machines, platform modules add OS-specific config, and each host can override further.

```
 ┌─────────────────────────────────────────────────────────┐
 │                       flake.nix                         │
 ├─────────────────────────────────────────────────────────┤
 │                    hosts/common/                        │  common
 │              packages · fonts · users                   │
 ├──────────────────────────┬──────────────────────────────┤
 │       hosts/darwin/      │        hosts/nixos/          │  platform
 ├─────────────┬────────────┼──────────────────────────────┤
 │  personal/  │   work/    │       homeserver/            │  layer / host
 ├───────┬─────┼──────┬─────┤                              │
 │ wagou │ old │ sap  │ pro │                              │
 └───────┴─────┴──────┴─────┴──────────────────────────────┘
```

## Structure

```
wagounix/
├── flake.nix          # Entrypoint — all configurations, checks, devShell
└── hosts/
    ├── common/        # Cross-platform — packages, fonts, users
    ├── darwin/        # macOS — platform config, settings, Homebrew, icons
    │   ├── personal/  # Personal Macs (wagou, wagou-old)
    │   └── work/      # Work Macs (sap, pro)
    └── nixos/         # NixOS — platform config, services
        └── homeserver/
```

<details>
<summary>Full directory tree</summary>

```
wagounix/
├── flake.nix
├── flake.lock
├── LICENSE
├── .mise.toml
├── .github/workflows/check.yml
│
└── hosts/
    ├── common/
    │   ├── default.nix
    │   ├── packages.nix
    │   ├── fonts.nix
    │   └── users.nix
    ├── darwin/
    │   ├── default.nix
    │   ├── configuration.nix
    │   ├── homebrew.nix
    │   ├── packages.nix
    │   ├── icons.nix
    │   ├── icons/                  # .icns icon files
    │   ├── settings/
    │   │   ├── default.nix
    │   │   ├── dock.nix
    │   │   ├── finder.nix
    │   │   ├── global-domain.nix
    │   │   ├── keyboard.nix
    │   │   └── ...
    │   ├── personal/
    │   │   ├── default.nix
    │   │   ├── dock.nix
    │   │   ├── packages.nix
    │   │   ├── homebrew.nix
    │   │   ├── wagou/
    │   │   │   ├── default.nix
    │   │   │   ├── variables.nix
    │   │   │   ├── packages.nix
    │   │   │   └── homebrew.nix
    │   │   └── wagou-old/
    │   │       ├── default.nix
    │   │       └── variables.nix
    │   └── work/
    │       ├── default.nix
    │       ├── dock.nix
    │       ├── packages.nix
    │       ├── homebrew.nix
    │       ├── sap/
    │       │   ├── default.nix
    │       │   ├── variables.nix
    │       │   ├── packages.nix
    │       │   └── homebrew.nix
    │       └── pro/
    │           ├── default.nix
    │           └── variables.nix
    └── nixos/
        ├── default.nix
        ├── configuration.nix
        └── homeserver/
            ├── default.nix
            ├── variables.nix
            ├── hardware.nix
            └── services.nix
```

</details>

## Hosts

### macOS

| Profile | System | Layer | Description |
|---------|--------|-------|-------------|
| `sap` | aarch64-darwin | work | SAP work Mac (legacy) |
| `wagou-old` | x86_64-darwin | personal | Old Intel Mac |
| `wagou` | aarch64-darwin | personal | New personal Mac |
| `pro` | aarch64-darwin | work | New work Mac |

### NixOS

| Profile | System | Description |
|---------|--------|-------------|
| `homeserver` | x86_64-linux | Home server (Docker, services) |

## Getting Started

### Bootstrap a fresh Mac

```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
sudo nix run nix-darwin -- switch --flake github:pierreWagou/wagounix#<profile>
```

<details>
<summary>Bootstrap NixOS</summary>

1. Install NixOS with flake support enabled
2. Clone this repo to `~/.config/wagounix`
3. Replace `hosts/nixos/homeserver/hardware.nix` with the output of `nixos-generate-config`
4. Run `sudo nixos-rebuild switch --flake ~/.config/wagounix#homeserver`

</details>

### Rebuild

```bash
# macOS
darwin-rebuild switch --flake ~/.config/wagounix#<profile>

# NixOS
sudo nixos-rebuild switch --flake ~/.config/wagounix#<profile>
```

## Development

Git hooks auto-install when entering the project directory (via [mise](https://mise.jdx.dev/)), or manually with `nix develop`.

### Hooks

Managed by [git-hooks.nix](https://github.com/cachix/git-hooks.nix):

| Stage | Check | Description |
|-------|-------|-------------|
| commit | **nixfmt** | Formatting |
| commit | **statix** | Anti-pattern linting |
| commit | **deadnix** | Unused code detection |

### CI

GitHub Actions runs on push to `main` and on PRs:

| Job | Runner | Profiles |
|-----|--------|----------|
| Lint | macos-15 | nixfmt, statix, deadnix |
| Build darwin | macos-15 | sap, wagou, pro (parallel) |
| Build NixOS | ubuntu-latest | homeserver |

## Quick Reference

| Action | Command |
|--------|---------|
| Rebuild Mac | `darwin-rebuild switch --flake .#<profile>` |
| Rebuild NixOS | `sudo nixos-rebuild switch --flake .#<profile>` |
| Test build (no activate) | `darwin-rebuild build --flake .#<profile>` |
| Update deps | `nix flake update` |
| Search package | `nix search nixpkgs <name>` |
| Run all checks | `nix flake check` |
| Enter dev shell | `nix develop` |

## License

[MIT](LICENSE)
