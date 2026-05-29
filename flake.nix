{
  description = "Wagounix — declarative system configuration for macOS and NixOS";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin-custom-icons = {
      url = "github:ryanccn/nix-darwin-custom-icons";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-dashlane = {
      url = "github:Dashlane/homebrew-tap";
      flake = false;
    };
    homebrew-alerter = {
      url = "github:vjeantet/homebrew-tap";
      flake = false;
    };
    # SAP-specific — remove when SAP Mac is returned
    homebrew-hai = {
      url = "git+https://github.tools.sap/hAIperspace/hai-homebrew.git";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      git-hooks,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # Overlay that patches television with the TTY fix from PR #1052
      # (sesh connect fails with "can't use /dev/tty" on macOS)
      # https://github.com/alexpasmantier/television/pull/1052
      # Remove once television >= 0.15.7 includes the fix
      televisionOverlay = final: prev: {
        television = prev.television.overrideAttrs (_: {
          version = "0.15.6-patched";
          src = final.fetchFromGitHub {
            owner = "joshmedeski";
            repo = "television";
            rev = "4ef7a9e98cdab3b129570d2af5569704a20b8666";
            hash = "sha256-ECaM8vwQ1gtkSJEPMBwvUIa3rpP7QU62P2yYEhtEKmQ=";
          };
        });
      };
    in
    {
      # -----------------------------------------------------------------------
      # macOS configurations
      # -----------------------------------------------------------------------
      darwinConfigurations = {

        sap = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            { nixpkgs.overlays = [ televisionOverlay ]; }
            ./hosts/common
            ./hosts/darwin
            ./hosts/darwin/work
            ./hosts/darwin/work/sap
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/work/sap/variables.nix;
          };
        };

        wagoumac = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            { nixpkgs.overlays = [ televisionOverlay ]; }
            ./hosts/common
            ./hosts/darwin
            ./hosts/darwin/personal
            ./hosts/darwin/personal/wagoumac
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/personal/wagoumac/variables.nix;
          };
        };

        wagouintel = nix-darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            { nixpkgs.overlays = [ televisionOverlay ]; }
            ./hosts/common
            ./hosts/darwin
            ./hosts/darwin/personal
            ./hosts/darwin/personal/wagouintel
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/personal/wagouintel/variables.nix;
          };
        };

        alan = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            { nixpkgs.overlays = [ televisionOverlay ]; }
            ./hosts/common
            ./hosts/darwin
            ./hosts/darwin/work
            ./hosts/darwin/work/alan
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/work/alan/variables.nix;
          };
        };

      };

      # -----------------------------------------------------------------------
      # NixOS configurations
      # -----------------------------------------------------------------------
      nixosConfigurations = {

        wagoulab = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            { nixpkgs.overlays = [ televisionOverlay ]; }
            inputs.sops-nix.nixosModules.sops
            inputs.quadlet-nix.nixosModules.quadlet
            ./hosts/common
            ./hosts/nixos
            ./hosts/nixos/wagoulab
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/nixos/wagoulab/variables.nix;
          };
        };

      };

      # -----------------------------------------------------------------------
      # Checks — run with `nix flake check`
      # -----------------------------------------------------------------------
      checks = import ./lib/checks.nix {
        inherit
          self
          nixpkgs
          git-hooks
          systems
          ;
      };

      # -----------------------------------------------------------------------
      # Dev shell — enter with `nix develop` or automatically via mise
      # Auto-installs git hooks on entry
      # -----------------------------------------------------------------------
      devShells = import ./lib/devshell.nix { inherit self nixpkgs systems; };
    };
}
