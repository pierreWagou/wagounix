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
│   │   │   └── wagou-mac/          # Personal Mac (aarch64-darwin)
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
│       └── wagoulab/              # Home server (x86_64-linux, prime + clone share common/)
│           ├── common/            # Shared config — services, shared secrets
│           │   ├── default.nix    # Imports services/
│           │   ├── secrets.yaml   # Shared sops-encrypted secrets
│           │   └── services/      # One dir per service: <name>/default.nix + secrets.yaml
│           │       ├── default.nix
│           │       ├── lib/web-service.nix  # mkWebService / mkPostgres / mkValkey helpers
│           │       ├── secrets.nix          # Shared-only secrets
│           │       └── <service>/           # vaultwarden, immich, seafile, authentik, ...
│           ├── prime/             # wagou-prime (primary)
│           │   ├── default.nix    # Imports hardware.nix + ../common
│           │   ├── variables.nix
│           │   └── hardware.nix   # Auto-generated hardware config (nixos-generate-config)
│           └── clone/             # wagou-clone (warm standby)
│               ├── default.nix    # Imports hardware.nix + ../common + services-disabled.nix
│               ├── variables.nix
│               ├── hardware.nix
│               └── services-disabled.nix  # Disables all quadlet containers by default
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

# NixOS hosts (prime + clone share common/)
wagou-prime = nixpkgs.lib.nixosSystem {
  modules = [
    inputs.sops-nix.nixosModules.sops      # secrets management
    inputs.quadlet-nix.nixosModules.quadlet # declarative Podman containers
    ./hosts/common              # common
    ./hosts/nixos               # platform
    ./hosts/nixos/wagoulab/common  # shared services + shared secrets
    ./hosts/nixos/wagoulab/prime   # primary: hardware.nix + variables
  ];
  specialArgs = { inherit inputs; host = import ./hosts/nixos/wagoulab/prime/variables.nix; };
};

wagou-clone = nixpkgs.lib.nixosSystem {
  modules = [
    inputs.sops-nix.nixosModules.sops
    inputs.quadlet-nix.nixosModules.quadlet
    ./hosts/common
    ./hosts/nixos
    ./hosts/nixos/wagoulab/common  # same shared services
    ./hosts/nixos/wagoulab/clone   # backup: hardware.nix + variables + services-disabled.nix
  ];
  specialArgs = { inherit inputs; host = import ./hosts/nixos/wagoulab/clone/variables.nix; };
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
  hostname = "wagou-prime";      # NixOS only (wagou-prime / wagou-clone)
  domain = "wagou.fr";                  # NixOS only
  serverIP = "192.168.68.66";           # NixOS only (prime .66, clone .62)
  tailscaleIP = "100.97.36.56";         # NixOS only (per machine)
  networkInterface = "enp170s0";        # NixOS only (per machine)
  lanSubnet = "192.168.68.0/24";        # NixOS only
  renderGroupGid = "303";               # NixOS only (Jellyfin/Immich HW transcode)
  timezone = "Europe/Paris";            # NixOS only
  acmeEmail = "pierre.romon@gmail.com"; # NixOS only
  adminEmail = "pierre.romon@gmail.com"; # NixOS only
  cloudflareAccountId = "...";          # NixOS only
  cloudflareTunnelId = "...";           # NixOS only (per machine: prime vs clone tunnel)
  serviceTunnelSubdomains = [ "vault" "pixel" "dash" "guard" "home" "tape" "dev" "apps" "relay" "cabas" "auth" "disk" "assets" "mailbox" "ai" "docs" "pantone" ]; # NixOS only — services managed by Podman/quadlet-nix (mirrored in prime/ and clone/variables.nix)
  appTunnelSubdomains = [ "creneau" "creneau-preview" ]; # NixOS only — apps managed by Dokploy
  dnsOnlySubdomains = [ "satisfactory" "mail" ]; # NixOS only — AdGuard rewrite only, no Traefik/tunnel (raw TCP/UDP)
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

Wagoulab hosts share `hosts/nixos/wagoulab/common/` (services + shared secrets). A new machine in the pair is a thin layer:

1. Create `hosts/nixos/wagoulab/<name>/variables.nix` (hostname, IPs, tunnel ID — mirror `serviceTunnelSubdomains` / `appTunnelSubdomains` / `dnsOnlySubdomains` from its sibling)
2. Create `hosts/nixos/wagoulab/<name>/default.nix` importing `hardware.nix` and `../common` (plus `services-disabled.nix` if it should idle like the clone)
3. Create `hosts/nixos/wagoulab/<name>/hardware.nix` (from `nixos-generate-config` on the target machine)
4. Add a `nixosConfigurations.<hostname>` entry in `flake.nix` following the prime/clone pattern above

For a brand-new unrelated NixOS host (not part of wagoulab): create `hosts/nixos/<hostname>/{default.nix,variables.nix,hardware.nix}` and add a `nixosConfigurations.<hostname>` entry.

## Adding a new NixOS service (wagoulab)

Services live in `hosts/nixos/wagoulab/common/services/<name>/` — one dir per service with `default.nix` (+ `secrets.yaml` if it needs secrets), built with the `lib/web-service.nix` helpers (`mkWebService`, `mkPostgres`, `mkValkey`). See the `homeserver` skill (canonical reference) for the full walkthrough. Summary:

1. Create `common/services/<name>/default.nix` using `ws.mkWebService { name, subdomain, image, port, ... }`
2. Import `./<name>` in `common/services/default.nix`
3. Add the subdomain to `serviceTunnelSubdomains` in **both** `prime/variables.nix` and `clone/variables.nix`
4. If secrets are needed: create `<name>/secrets.yaml` (via `sops`), declare with `sopsFile = ./secrets.yaml` in the service module (`.sops.yaml` already covers `services/*/secrets.yaml`)

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
- **build-darwin** — wagou-mac, alan-mac (macos-15, parallel)
- **build-nixos** — wagou-prime, wagou-clone (ubuntu-latest)

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
- macOS: Nix daemon is managed by the standard Nix installer (`nix.enable = false` in darwin config)
- NixOS: `system.stateVersion` must match the version at install time — never change it
- NixOS: `hardware.nix` is auto-generated per machine (`prime/`, `clone/`) — replace with real one from the server
- NixOS services: one dir per service in `common/services/<name>/`, built with `lib/web-service.nix` — don't hand-write Traefik labels; secrets colocated (`sopsFile = ./secrets.yaml`); see `homeserver` skill for the canonical walkthrough
- Commit and push after successful rebuilds
