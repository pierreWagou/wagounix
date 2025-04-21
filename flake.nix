{
  description = "SAP nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
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
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, nixpkgs, home-manager, catppuccin, homebrew-core, homebrew-cask, homebrew-dashlane }: {
    darwinConfigurations = {
      sap = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "I544489";
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "Dashlane/homebrew-taps" = homebrew-dashlane;
              };
              mutableTaps = false;
            };
          }
          ./homebrew.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.I544489 = {
              imports = [
                ./users/I544489/home.nix
                catppuccin.homeModules.catppuccin
              ];
            };
          }
        ];
      };
    };
  };
}