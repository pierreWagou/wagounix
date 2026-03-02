{
  description = "SAP nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
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
    homebrew-speedtest = {
      url = "github:teamookla/homebrew-speedtest";
      flake = false;
    };
    homebrew-hai = {
      url = "https://github.tools.sap/hAIperspace/hai-homebrew.git";
      flake = false;
    };
    homebrew-cline = {
      url = "github:cline/homebrew-cline";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-homebrew, darwin-custom-icons, ... }: {
    darwinConfigurations = {
      sap = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./core.nix
          ./homebrew.nix
          ./icons.nix
        ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}