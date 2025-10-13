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
    homebrew-speedtest = {
      url = "github:teamookla/homebrew-speedtest";
      flake = false;
    };
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    darwin-custom-icons.url = "github:ryanccn/nix-darwin-custom-icons";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, nixpkgs, home-manager, homebrew-core, homebrew-cask, homebrew-dashlane, homebrew-speedtest, spicetify-nix, catppuccin, darwin-custom-icons, sops-nix }: {
    darwinConfigurations = {
      sap = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./configuration.nix
          ./home_manager.nix
          ./homebrew.nix
          ./icons.nix
        ];
        specialArgs = { inherit inputs;};
      };
    };
  };
}