# SteamOS (Steam Deck / Steam Machine) — declarative packages via wagounix

Stock SteamOS stays untouched. Nix + standalone home-manager sync the
wagounix common package set onto the device. One command, exact match:

```sh
home-manager switch --flake github:pierreWagou/wagounix#deck@steamos
```

## One-time device setup

1. Switch to Desktop Mode, open Konsole.
2. Install Nix with the Determinate installer (Steam Deck planner —
   handles the read-only root and `/nix` persistence across SteamOS updates):
   ```sh
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install steam-deck
   ```
   Re-open the shell afterwards so `nix` is on `PATH`.
3. No home-manager install needed — bootstrap straight from the flake:
   ```sh
   nix build github:pierreWagou/wagounix#homeConfigurations."deck@steamos".activationPackage
   ./result/activate
   ```
   Afterwards `home-manager switch --flake github:pierreWagou/wagounix#deck@steamos`
   re-syncs after every flake change (installs missing, removes dropped).

## Scope and limits

- **Packages only** (`home.packages` = full `hosts/common` set). No system
  modules: SteamOS is Arch, so no NixOS kernel/services/users management.
- **Dotfiles stay with chezmoi** — home-manager does not manage any dotfiles here.
- **GUI apps**: prefer Flatpak/Discover — Nix GUI apps don't integrate with
  Game Mode. Nix owns CLI/TUI/dev tools.
- Unpatched third-party binaries may need `nix-ld`; Nix-built packages are fine.
