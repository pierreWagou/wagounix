<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&height=220&color=0:cba6f7,25:b4befe,50:89dceb,75:f5c2e7,100:f38ba8&text=Wagounix&fontSize=60&fontColor=11111b&desc=one%20flake%20to%20rule%20them%20all&descSize=18&descAlignY=62&descAlign=50&fontAlignY=38&animation=fadeIn&fontAlign=50)

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
  ┌───────────────────────────────────────────────────────────────┐
  │                         flake.nix                             │
  ├───────────────────────────────────────────────────────────────┤
  │                      hosts/common/                            │  common
  │                packages · fonts · users                       │
  ├──────────────────────────────────┬────────────────────────────┤
  │         hosts/darwin/            │        hosts/nixos/        │  platform
  ├────────────────┬─────────────────┼────────────────────────────┤
  │   personal/    │     work/       │        wagoulab/           │  layer / host
  ├────────┬───────┼──────┬──────────┤                            │
  │wagoumac│wagou- │ sap  │  alan    │                            │
  │        │ intel │      │          │                            │
  └────────┴───────┴──────┴──────────┴────────────────────────────┘
```

## Structure

```
wagounix/
├── flake.nix          # Entrypoint — all configurations, checks, devShell
└── hosts/
    ├── common/        # Cross-platform — packages, fonts, users
    ├── darwin/        # macOS — platform config, settings, Homebrew, icons
    │   ├── personal/  # Personal Macs (wagoumac, wagouintel)
    │   └── work/      # Work Macs (sap, alan)
    └── nixos/         # NixOS — platform config, services
        └── wagoulab/
```

<details>
<summary>Full directory tree</summary>

```
wagounix/
├── flake.nix
├── flake.lock
├── .sops.yaml
├── LICENSE
├── .mise.toml
├── .github/workflows/check.yml
├── lib/
│   ├── checks.nix
│   └── devshell.nix
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
    │   │   ├── wagoumac/
    │   │   │   ├── default.nix
    │   │   │   ├── variables.nix
    │   │   │   └── homebrew.nix
    │   │   └── wagouintel/
    │   │       ├── default.nix
    │   │       └── variables.nix
    │   └── work/
    │       ├── default.nix
    │       ├── dock.nix
    │       ├── homebrew.nix
    │       ├── sap/
    │       │   ├── default.nix
    │       │   ├── variables.nix
    │       │   └── homebrew.nix
    │       └── alan/
    │           ├── default.nix
    │           └── variables.nix
    └── nixos/
        ├── default.nix
        ├── configuration.nix
        └── wagoulab/
            ├── default.nix
            ├── variables.nix
            ├── hardware.nix
            ├── secrets.yaml
            └── services/
                ├── default.nix
                ├── podman.nix
                ├── secrets.nix
                ├── traefik.nix
                ├── vaultwarden.nix
                ├── opencloud.nix
                ├── immich.nix
                ├── adguardhome.nix
                ├── cloudflared.nix
                ├── tailscale.nix
                ├── homepage.nix
                ├── homepage-images/
                ├── home-assistant.nix
                ├── jellyfin.nix
                ├── fail2ban.nix
                ├── firewall.nix
                ├── ttyd.nix
                ├── rbw.nix
                ├── creneau.nix
                ├── webhook.nix
                ├── renovate.nix
                └── kitchenowl.nix
```

</details>

## Hosts

### macOS

| Profile | System | Layer | Description |
|---|---|---|---|
| `sap` | aarch64-darwin | work | SAP work Mac (legacy) |
| `wagoumac` | aarch64-darwin | personal | Personal Mac (Apple Silicon) |
| `wagouintel` | x86_64-darwin | personal | Personal Mac (Intel) |
| `alan` | aarch64-darwin | work | New work Mac |

### NixOS

| Profile | System | Description |
|---|---|---|
| `wagoulab` | x86_64-linux | Home server (Podman, services) |

## Getting Started

### macOS

Profiles: `wagoumac`, `wagouintel`, `sap`, `alan`

```bash
# 1. Install Lix (Nix)
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# 2. Apply the configuration
sudo nix run nix-darwin -- switch --flake github:pierreWagou/wagounix#<profile>
```

### NixOS

Profiles: `wagoulab`

```bash
# 1. Install NixOS with Lix
sh <(curl -L https://install.lix.systems/lix) install

# 2. Apply the configuration
sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagoulab --refresh
```

> Note: `hosts/nixos/<host>/hardware.nix` must be generated on the target machine (`sudo nixos-generate-config --show-hardware-config`) and committed to the repo before the first deploy.

### Rebuild

```bash
# macOS
darwin-rebuild switch --flake ~/.config/wagounix#<profile>

# NixOS (local)
sudo nixos-rebuild switch --flake ~/.config/wagounix#wagoulab

# NixOS (from GitHub, on server)
sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagoulab --refresh
```

## Development

Git hooks auto-install when entering the project directory (via [mise](https://mise.jdx.dev/)), or manually with `nix develop`.

### Hooks

Managed by [git-hooks.nix](https://github.com/cachix/git-hooks.nix):

| Stage | Check | Description |
|---|---|---|
| commit | **nixfmt** | Formatting |
| commit | **statix** | Anti-pattern linting |
| commit | **deadnix** | Unused code detection |

### CI

GitHub Actions runs on push to `main` and on PRs:

| Job | Runner | Profiles |
|---|---|---|
| Lint | ubuntu-latest | nixfmt, statix, deadnix |
| Build darwin | macos-15 | sap, wagoumac, alan (parallel) |
| Build NixOS | ubuntu-latest | wagoulab |

> Note: `wagouintel` (x86_64-darwin) is not built in CI — GitHub Actions no longer offers Intel macOS runners for free.

## Quick Reference

| Action | Command |
|---|---|
| Rebuild Mac | `darwin-rebuild switch --flake .#<profile>` |
| Rebuild NixOS | `sudo nixos-rebuild switch --flake .#<profile>` |
| Test build (no activate) | `darwin-rebuild build --flake .#<profile>` |
| Update deps | `nix flake update` |
| Search package | `nix search nixpkgs <name>` |
| Run all checks | `nix flake check` |
| Enter dev shell | `nix develop` |

## License

[MIT](LICENSE)
