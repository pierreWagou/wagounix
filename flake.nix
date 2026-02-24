{
  description = "SAP nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    darwin-custom-icons.url = "github:ryanccn/nix-darwin-custom-icons";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, nixpkgs, home-manager, spicetify-nix, catppuccin, darwin-custom-icons, ... }: {
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