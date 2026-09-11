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
        "x86_64-linux"
      ];

    in
    {
      # -----------------------------------------------------------------------
      # macOS configurations
      # -----------------------------------------------------------------------
      darwinConfigurations = {

        wagou-mac = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/common
            ./hosts/darwin
            ./hosts/darwin/personal
            ./hosts/darwin/personal/wagou-mac
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/personal/wagou-mac/variables.nix;
          };
        };

        alan-mac = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/common
            ./hosts/darwin
            ./hosts/darwin/alan-mac
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/alan-mac/variables.nix;
          };
        };

      };

      # -----------------------------------------------------------------------
      # NixOS configurations
      # -----------------------------------------------------------------------
      nixosConfigurations = {

        wagou-prime = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.quadlet-nix.nixosModules.quadlet
            ./hosts/common
            ./hosts/nixos
            ./hosts/nixos/wagoulab/common
            ./hosts/nixos/wagoulab/prime
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/nixos/wagoulab/prime/variables.nix;
          };
        };

        wagou-clone = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.quadlet-nix.nixosModules.quadlet
            ./hosts/common
            ./hosts/nixos
            ./hosts/nixos/wagoulab/common
            ./hosts/nixos/wagoulab/clone
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/nixos/wagoulab/clone/variables.nix;
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
