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
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Common modules shared across all platforms
      commonModules = [
        ./packages.nix
        ./fonts.nix
        ./users.nix
      ];
    in
    {
      # -----------------------------------------------------------------------
      # macOS configurations
      # -----------------------------------------------------------------------
      darwinConfigurations = {

        sap = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = commonModules ++ [
            ./hosts/darwin
            ./hosts/darwin/work
            ./hosts/darwin/work/sap
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/work/sap/variables.nix;
          };
        };

        wagou-old = nix-darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = commonModules ++ [
            ./hosts/darwin
            ./hosts/darwin/personal
            ./hosts/darwin/personal/wagou-old
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/personal/wagou-old/variables.nix;
          };
        };

        wagou = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = commonModules ++ [
            ./hosts/darwin
            ./hosts/darwin/personal
            ./hosts/darwin/personal/wagou
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/personal/wagou/variables.nix;
          };
        };

        pro = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = commonModules ++ [
            ./hosts/darwin
            ./hosts/darwin/work
            ./hosts/darwin/work/pro
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/darwin/work/pro/variables.nix;
          };
        };

      };

      # -----------------------------------------------------------------------
      # NixOS configurations
      # -----------------------------------------------------------------------
      nixosConfigurations = {

        homeserver = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules ++ [
            ./hosts/nixos
            ./hosts/nixos/homeserver
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/nixos/homeserver/variables.nix;
          };
        };

      };

      # -----------------------------------------------------------------------
      # Checks — run with `nix flake check`
      # -----------------------------------------------------------------------
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              statix.enable = true;
              deadnix.enable = true;

              darwin-build = {
                enable = true;
                name = "darwin-build";
                entry = "${pkgs.writeShellScript "check-darwin-builds" ''
                  ${pkgs.nix}/bin/nix build path:.#darwinConfigurations.sap.system --no-link 2>&1
                  ${pkgs.nix}/bin/nix build path:.#darwinConfigurations.wagou.system --no-link 2>&1
                  ${pkgs.nix}/bin/nix build path:.#darwinConfigurations.pro.system --no-link 2>&1
                  ${pkgs.nix}/bin/nix build path:.#darwinConfigurations.wagou-old.system --no-link 2>&1
                ''}";
                pass_filenames = false;
                stages = [ "pre-push" ];
              };
            };
          };
        in
        {
          inherit pre-commit-check;
        }
        // nixpkgs.lib.optionalAttrs (system == "aarch64-darwin") {
          sap = self.darwinConfigurations.sap.system;
          wagou = self.darwinConfigurations.wagou.system;
          pro = self.darwinConfigurations.pro.system;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-darwin") {
          wagou-old = self.darwinConfigurations.wagou-old.system;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          homeserver = self.nixosConfigurations.homeserver.config.system.build.toplevel;
        }
      );

      # -----------------------------------------------------------------------
      # Dev shell — enter with `nix develop` or automatically via mise
      # Auto-installs git hooks on entry
      # -----------------------------------------------------------------------
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
        in
        {
          default = pkgs.mkShell {
            inherit shellHook;
            buildInputs = enabledPackages;
          };
        }
      );
    };
}
