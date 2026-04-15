{
  description = "Wagounix nix-darwin system flake";

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
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      darwinConfigurations = {

        # -----------------------------------------------------------------------
        # SAP work Mac (legacy — remove when returned)
        # -----------------------------------------------------------------------
        sap = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./configuration.nix
            ./packages.nix
            ./homebrew.nix
            ./fonts.nix
            ./icons.nix
            ./hosts/work
            ./hosts/work/sap
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/work/sap/variables.nix;
          };
        };

        # -----------------------------------------------------------------------
        # Old personal Mac (Intel x86_64)
        # -----------------------------------------------------------------------
        wagou-old = nix-darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            ./configuration.nix
            ./packages.nix
            ./homebrew.nix
            ./fonts.nix
            ./icons.nix
            ./hosts/personal
            ./hosts/personal/wagou-old
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/personal/wagou-old/variables.nix;
          };
        };

        # -----------------------------------------------------------------------
        # New personal Mac (Apple Silicon)
        # -----------------------------------------------------------------------
        wagou = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./configuration.nix
            ./packages.nix
            ./homebrew.nix
            ./fonts.nix
            ./icons.nix
            ./hosts/personal
            ./hosts/personal/wagou
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/personal/wagou/variables.nix;
          };
        };

        # -----------------------------------------------------------------------
        # New work Mac (Apple Silicon)
        # -----------------------------------------------------------------------
        pro = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./configuration.nix
            ./packages.nix
            ./homebrew.nix
            ./fonts.nix
            ./icons.nix
            ./hosts/work
            ./hosts/work/pro
          ];
          specialArgs = {
            inherit inputs;
            host = import ./hosts/work/pro/variables.nix;
          };
        };

      };

      # -------------------------------------------------------------------------
      # Checks — run with `nix flake check`
      # Includes git-hooks + darwin configuration builds
      # -------------------------------------------------------------------------
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
          sap = self.darwinConfigurations.sap.system;
          wagou = self.darwinConfigurations.wagou.system;
          pro = self.darwinConfigurations.pro.system;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-darwin") {
          wagou-old = self.darwinConfigurations.wagou-old.system;
        }
      );

      # -------------------------------------------------------------------------
      # Dev shell — enter with `nix develop` or automatically via direnv
      # Auto-installs git hooks on entry
      # -------------------------------------------------------------------------
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
