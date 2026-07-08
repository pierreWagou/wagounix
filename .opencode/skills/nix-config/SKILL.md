---
name: nix-config
description: Full reference for the wagounix flake — repo structure, module wiring, adding packages/hosts/settings, dev workflow, and Nix language patterns
---

## Repository structure

```
wagounix/
├── flake.nix              # All inputs, darwinConfigurations, nixosConfigurations, checks, devShell
├── flake.lock             # Pinned dependency versions
├── .sops.yaml             # sops-nix encryption rules (age public keys)
├── .mise.toml             # Auto-activates nix develop on cd (installs git hooks)
├── lib/
│   ├── checks.nix         # Flake checks (lint + build all configs)
│   └── devshell.nix       # Dev shell definition (sops, ssh-to-age, git hooks)
│
├── hosts/
│   ├── common/                    # Cross-platform modules
│   │   ├── default.nix            # Imports packages, fonts, users
│   │   ├── packages.nix           # Cross-platform CLI packages (all machines)
│   │   ├── fonts.nix              # Cross-platform fonts (all machines)
│   │   └── users.nix              # Cross-platform user config (all machines)
│   ├── darwin/                    # macOS platform base
│   │   ├── default.nix            # Imports configuration, dock, homebrew, icons, packages, settings
│   │   ├── configuration.nix      # nix-darwin system config (stateVersion, PAM Touch ID)
│   │   ├── dock.nix               # wagou.dock options module (dock app categories)
│   │   ├── homebrew.nix           # Common Homebrew brews, casks, taps
│   │   ├── icons.nix              # Custom macOS app icons
│   │   ├── packages.nix           # Darwin-only nix packages (cocoapods, spicetify, etc.)
│   │   ├── icons/                 # .icns icon files
│   │   ├── settings/              # macOS system defaults
│   │   │   ├── default.nix        # Imports all settings modules
│   │   │   ├── dock.nix
│   │   │   ├── finder.nix
│   │   │   ├── keyboard.nix
│   │   │   └── ...
│   │   ├── personal/              # Personal Mac layer
│   │   │   ├── default.nix        # Imports packages, homebrew
│   │   │   ├── packages.nix       # Personal nix packages (android-tools, mas)
│   │   │   ├── homebrew.nix       # Personal casks (Steam, Ankama, etc.) + masApps
│   │   │   └── wagoumac/          # Personal Mac (aarch64-darwin)
│   │   │       ├── default.nix
│   │   │       └── variables.nix
│   │   └── alan/                  # Work Mac (aarch64-darwin)
│   │       ├── default.nix    # Imports homebrew, packages; sets wagou.dock
│   │       ├── variables.nix
│   │       ├── homebrew.nix   # 1password, figma, notion, slack
│   │       └── packages.nix   # awscli2, 1password-cli
│   └── nixos/                     # NixOS platform base
│       ├── default.nix            # Imports configuration, packages
│       ├── configuration.nix      # NixOS system config (SSH, auto-updates, users)
│       ├── packages.nix           # NixOS-only packages (ghostty.terminfo, ventoy)
│       └── wagoulab/              # Home server (x86_64-linux)
│           ├── default.nix
│           ├── variables.nix
│           ├── hardware.nix       # Auto-generated hardware config (nixos-generate-config)
│           ├── secrets.yaml       # sops-encrypted secrets (age)
│           └── services/          # Service modules (one file per service)
│               ├── default.nix
│               ├── podman.nix
│               ├── secrets.nix
│               ├── traefik.nix
│               ├── vaultwarden.nix
│               ├── seafile/
│               ├── immich.nix
│               ├── adguardhome.nix
│               ├── cloudflared.nix
│               ├── tailscale.nix
│               ├── homepage/
│               ├── branding.nix
│               ├── branding-assets/
│               ├── authentik/
│               ├── home-assistant.nix
│               ├── jellyfin.nix
│               ├── kitchenowl.nix
│               ├── dokploy.nix
│               ├── renovate.nix
│               ├── webhook.nix
│               ├── fail2ban.nix
│               ├── firewall.nix
│               ├── ttyd.nix
│               └── rbw.nix
│
└── .github/workflows/check.yml   # CI: lint + build darwin + build NixOS
```

## How the flake is wired

### Module layering

Each configuration loads modules in order:

1. **Common** (cross-platform) — `hosts/common` (packages, fonts, users)
2. **Platform** — `hosts/darwin` or `hosts/nixos`
3. **Host** — `hosts/<platform>/<host>` (or `hosts/<platform>/<layer>/<host>` when a layer is used)

In `flake.nix`, this is expressed as:

```nix
# Darwin host (modules are inlined per host — there is no shared `commonModules` var)
alan = nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./hosts/common              # common
    ./hosts/darwin              # platform
    ./hosts/darwin/alan         # host
  ];
  specialArgs = { inherit inputs; host = import ./hosts/darwin/alan/variables.nix; };
};

# NixOS host
wagoulab = nixpkgs.lib.nixosSystem {
  modules = [
    inputs.sops-nix.nixosModules.sops      # secrets management
    inputs.quadlet-nix.nixosModules.quadlet # declarative Podman containers
    ./hosts/common              # common
    ./hosts/nixos               # platform
    ./hosts/nixos/wagoulab      # host
  ];
  specialArgs = { inherit inputs; host = import ./hosts/nixos/wagoulab/variables.nix; };
};
```

Nix **merges lists** from all modules automatically — packages from each layer are combined, not replaced.

### Host variables pattern

Each host has a `variables.nix` that exports a plain attribute set (not a module):

```nix
rec {
  username = "wagou";
  homeDir = "/Users/${username}";     # /home/${username} for NixOS
  enableRosetta = false;                # darwin only
  hostname = "wagoulab";              # NixOS only
  domain = "wagou.fr";                  # NixOS only
  serverIP = "192.168.68.65";           # NixOS only
  tailscaleIP = "100.68.157.70";        # NixOS only
  networkInterface = "enp170s0";        # NixOS only
  lanSubnet = "192.168.68.0/24";        # NixOS only
  renderGroupGid = "303";               # NixOS only (Jellyfin/Immich HW transcode)
  timezone = "Europe/Paris";            # NixOS only
  acmeEmail = "pierre.romon@gmail.com"; # NixOS only
  adminEmail = "pierre.romon@gmail.com"; # NixOS only
  cloudflareAccountId = "...";          # NixOS only
  cloudflareTunnelId = "...";           # NixOS only
  serviceTunnelSubdomains = [ "vault" "pixel" "dash" "guard" "home" "tape" "dev" "apps" "relay" "cabas" "auth" "disk" "assets" ]; # NixOS only — services managed by Podman/quadlet-nix
  appTunnelSubdomains = [ "creneau" "creneau-preview" ]; # NixOS only — apps managed by Dokploy
  valkeyImage = "docker.io/valkey/valkey:9.1.0"; # NixOS only (shared by immich, authentik, seafile Redis)
  podmanCIDRs = [ "10.89.0.0/16" "172.16.0.0/12" ]; # NixOS only
  ports = { ttyd = 7681; webhook = 9000; }; # NixOS only
  latitude = 48.8566;                   # NixOS only (for weather widgets)
  longitude = 2.3522;                   # NixOS only
}
```

These are passed via `specialArgs` and available in all modules as `{ host, ... }:`.

## Adding packages

### Cross-platform CLI tool (all machines)

Edit `hosts/common/packages.nix`:
```nix
environment.systemPackages = with pkgs; [ ... new-package ... ];
```

### Darwin-only CLI tool

Edit `hosts/darwin/packages.nix`.

### Layer-specific or host-specific

Edit the appropriate `packages.nix` under `hosts/darwin/<layer>/` or `hosts/darwin/<layer>/<host>/`.

### Homebrew cask (GUI app)

Edit the appropriate `homebrew.nix` and add to the `casks` list.

### Homebrew brew (CLI formula)

Edit the appropriate `homebrew.nix` and add to the `brews` list.

### Mac App Store app

Add to `masApps` in the appropriate `homebrew.nix`:
```nix
masApps = { "App Name" = 123456789; };
```

## Adding a new darwin host

1. Choose the layer (`personal` or `work`)
2. Create `hosts/darwin/<layer>/<hostname>/variables.nix`:
   ```nix
   rec {
     username = "myuser";
     homeDir = "/Users/${username}";
     enableRosetta = false;
   }
   ```
3. Create `hosts/darwin/<layer>/<hostname>/default.nix`:
   ```nix
   _: { }
   ```
4. Add a `darwinConfigurations.<hostname>` entry in `flake.nix`:
   ```nix
   <hostname> = nix-darwin.lib.darwinSystem {
     system = "aarch64-darwin";
     modules = [
       ./hosts/common
       ./hosts/darwin
       ./hosts/darwin/<layer>
       ./hosts/darwin/<layer>/<hostname>
     ];
     specialArgs = {
       inherit inputs;
       host = import ./hosts/darwin/<layer>/<hostname>/variables.nix;
     };
   };
   ```

## Adding a new NixOS host

1. Create `hosts/nixos/<hostname>/variables.nix`:
   ```nix
   rec {
     username = "myuser";
     homeDir = "/home/${username}";
     hostname = "<hostname>";
   }
   ```
2. Create `hosts/nixos/<hostname>/default.nix` with imports for hardware and services
3. Create `hosts/nixos/<hostname>/hardware.nix` (from `nixos-generate-config` on the target machine)
4. Create `hosts/nixos/<hostname>/services/` directory for host-specific services (one file per service)
5. Add a `nixosConfigurations.<hostname>` entry in `flake.nix`

## Adding macOS settings

1. Create `hosts/darwin/settings/<category>.nix`:
   ```nix
   _: {
     system.defaults.<namespace> = {
       option = value;
     };
   }
   ```
2. Add it to the imports in `hosts/darwin/settings/default.nix`

Common `system.defaults` namespaces: `dock`, `finder`, `NSGlobalDomain`, `trackpad`, `CustomUserPreferences`, `menuExtraClock`, `screencapture`, `screensaver`, `spaces`, `controlcenter`, `magicmouse`, `SoftwareUpdate`.

## Configuring the dock

`hosts/darwin/dock.nix` defines a custom `wagou.dock` options module that assembles the dock's persistent apps from named categories. Set the categories in a layer (`personal`/`work`) or host `default.nix`:

```nix
wagou.dock = {
  communication = [ "/Applications/Thunderbird.app" "/Applications/Slack.app" ];
  browser = [ "/Applications/Zen.app" ];
  development = [ "/Applications/Visual Studio Code.app" "/Applications/Ghostty.app" ];
  others = [ "/Applications/Spotify.app" ];
};
```

Categories: `communication`, `browser`, `development`, `others`. Each darwin host inherits defaults and can override per category.

## Adding custom icons

1. Place `.icns` file in `hosts/darwin/icons/`
2. Add an entry in `hosts/darwin/icons.nix`:
   ```nix
   { path = "/Applications/AppName.app"; icon = ./icons/appname.icns; }
   ```

## Adding a Homebrew tap

1. Add the tap as a flake input in `flake.nix`:
   ```nix
   homebrew-newtap = { url = "github:owner/homebrew-repo"; flake = false; };
   ```
2. Register it in `nix-homebrew.taps` in the appropriate `homebrew.nix`:
   ```nix
   nix-homebrew.taps = { "owner/homebrew-repo" = inputs.homebrew-newtap; };
   ```

## Nix language essentials

```nix
# Attribute set
{ key = "value"; nested = { a = 1; }; }

# List
[ "one" "two" "three" ]

# with expression (bring attrs into scope)
environment.systemPackages = with pkgs; [ git vim tmux ];

# String interpolation
home = "${host.homeDir}/Downloads";

# rec — self-referencing attrset
rec { username = "me"; homeDir = "/Users/${username}"; }

# inherit — shorthand for x = x
specialArgs = { inherit inputs; };

# Function with destructured attrset argument
{ pkgs, lib, ... }:
{
  # module body
}

# Unused arguments
_: { }
```

### Module system

- Modules are functions that return attribute sets of option values
- Multiple modules setting the same **list** option are **merged** (e.g., `environment.systemPackages`)
- Multiple modules setting the same **scalar** option will **conflict**
- Use `lib.mkForce` to override, `lib.mkDefault` for low-priority defaults
- Use `lib.mkIf <condition> { ... }` for conditional configuration

## Development workflow

### Pre-commit hooks (git-hooks.nix)

Hooks auto-install when entering the dev shell. On every commit:
- **nixfmt** — formatting check
- **statix** — lint for anti-patterns
- **deadnix** — find unused code

Full builds are verified by CI after push.

### Dev shell

```bash
nix develop          # manual entry
# or just cd into the repo — mise auto-activates via .mise.toml
```

### Flake checks

```bash
nix flake check      # runs all checks + builds
```

### CI (GitHub Actions)

- **lint** — nixfmt, statix, deadnix (ubuntu-latest)
- **build-darwin** — wagoumac, alan (macos-15, parallel)
- **build-nixos** — wagoulab (ubuntu-latest)

## Key commands

| Command | What it does |
|---|---|
| `darwin-rebuild switch --flake .#<profile>` | Build and activate macOS config |
| `darwin-rebuild build --flake .#<profile>` | Build without activating (test) |
| `sudo nixos-rebuild switch --flake .#<profile>` | Build and activate NixOS config |
| `nix search nixpkgs <name>` | Search for a package |
| `nix flake update` | Update all inputs |
| `nix flake update <input>` | Update a single input |
| `nix develop` | Enter dev shell (installs hooks) |
| `nix flake check` | Run all checks |

## Important rules

- ALWAYS work in `~/Projects/wagou/wagounix/` — this is the source of truth
- Use `build` first to test, then `switch` to activate
- When adding a package, check if it exists: `nix search nixpkgs <name>`
- GUI apps -> Homebrew casks; CLI tools -> nix packages (prefer nix when available)
- `onActivation.cleanup = "uninstall"` — removing a cask/brew from config WILL uninstall it
- `mutableTaps = false` — add new taps as flake inputs
- No home-manager — user dotfiles are managed by chezmoi separately
- macOS: Nix daemon is managed by Lix installer (`nix.enable = false` in darwin config)
- NixOS: `system.stateVersion` must match the version at install time — never change it
- NixOS: `hardware.nix` is auto-generated — replace placeholder with real one from the server
- Commit and push after successful rebuilds
