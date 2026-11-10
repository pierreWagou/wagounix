# Wagounix — Agent Guide

Declarative Nix flake for macOS (`nix-darwin`) + NixOS. Source of truth: `~/Projects/wagou/wagounix/`.

## Layout

- `flake.nix` — all inputs, `darwinConfigurations` (`wagou-mac`, `alan-mac` / `aarch64-darwin`), `nixosConfigurations` (`wagou-prime`, `wagou-clone` / `x86_64-linux`), `checks`, `devShells`
- `hosts/common/` — cross-platform (packages, fonts, users)
- `hosts/darwin/` — macOS platform + `personal/` / `alan-mac/` layers + per-host `<layer>/<host>/{default.nix,variables.nix}`
- `hosts/nixos/wagoulab/{common,prime,clone}/` — server config, `variables.nix` per machine (`prime`/`clone`), shared `common/services/<name>/` (one dir per service: `default.nix` + `secrets.yaml` via `lib/web-service.nix`)
- `lib/checks.nix`, `lib/devshell.nix` — `nix flake check` + dev shell
- `.sops.yaml` — age keys + encryption rules; `.mise.toml` — auto-enters `nix develop` on `cd` (installs git hooks)

Module layering per host: `hosts/common` → platform (`hosts/darwin` or `hosts/nixos`) → host dir. `specialArgs = { inherit inputs; host = import .../variables.nix; }` — host identity comes from `variables.nix`, never hardcode hostnames/IPs. Lists (e.g. `environment.systemPackages`) merge across modules; scalars conflict.

## Skills

Detailed references live in `.agents/skills/`. Load them before non-trivial work:

- `nix-config` — repo structure, module wiring, adding packages/hosts/settings, Nix patterns, dev workflow
- `homeserver` — `wagoulab` services, secrets, DNS/Traefik/Cloudflare Tunnel, backups/failover, troubleshooting

`AGENTS.md` is the index; skills are authoritative on their topics. Don't duplicate them here.

## Commands

```bash
nix flake check                                            # lint (nixfmt, statix, deadnix) + build all configs
nix develop                                                # dev shell (sops, ssh-to-age, hooks); auto via mise on cd
darwin-rebuild switch --flake .#<wagou-mac|alan-mac>       # macOS activate (use `build` first to test)
sudo nixos-rebuild switch --flake .#<wagou-prime|wagou-clone>  # NixOS activate
sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagou-prime --refresh  # rebuild on server
nix search nixpkgs <name>                                  # package search
nix flake update [<input>]                                 # update deps
```

CI (`.github/workflows/check.yml`): lint + build darwin (macos-15) + build NixOS on push to `main`/PRs.

## Conventions

- New packages: cross-platform → `hosts/common/packages.nix`; darwin-only → `hosts/darwin/packages.nix`; layer/host-specific → its `packages.nix`. GUI apps → Homebrew casks in `homebrew.nix`; CLI → nix packages. `onActivation.cleanup = "uninstall"` means removal uninstalls; `mutableTaps = false` means new taps must be flake inputs.
- New darwin host: `<layer>/<host>/{default.nix,variables.nix}` + `darwinConfigurations` entry in `flake.nix` (see `nix-config` skill).
- New NixOS service: `common/services/<name>/default.nix` (dir per service, built with `lib/web-service.nix` `mkWebService`/`mkPostgres`/`mkValkey`) + import `./<name>` in `services/default.nix` + subdomain in `serviceTunnelSubdomains` (`prime`/`clone` `variables.nix`). Secrets colocated as `<name>/secrets.yaml` with `sopsFile`. User-built apps go to Dokploy, not NixOS config (see `homeserver` skill).
- macOS settings: new file in `hosts/darwin/settings/` + import in its `default.nix`.
- No home-manager — dotfiles are chezmoi-managed elsewhere.

## Secrets (sops-nix)

- Encrypted `secrets.yaml` at `common/` (shared) and colocated per service (`common/services/<name>/secrets.yaml` with `sopsFile = ./secrets.yaml`); rules in `.sops.yaml` (keys: admin + all machines).
- Edit with `sops hosts/.../secrets.yaml` inside `nix develop`; shared secrets declared in `common/services/secrets.nix`, per-service secrets in `<name>/default.nix` with `sopsFile = ./secrets.yaml`; use `config.sops.placeholder.*` templates for `KEY=VALUE` env files. Never commit plaintext.
- See `homeserver` skill for key locations, adding secrets, and recovery.

## Don'ts

- Don't hand-edit `flake.lock`; don't `--no-verify` bypass hooks; don't add flake inputs without `inputs.nixpkgs.follows` where applicable.
- Don't change `system.stateVersion`; don't commit another machine's `hardware.nix` (generate on target via `nixos-generate-config`).
- Don't build user apps on the server — build in CI, push to GHCR, Dokploy pulls.
- Commit + push after successful rebuilds; rebuild both NixOS machines to keep prime/clone in sync.
