{
  description = "SAP nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin-custom-icons = {
      url = "github:ryanccn/nix-darwin-custom-icons";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    # homebrew-dashlane = {
    #   url = "github:Dashlane/homebrew-tap";
    #   flake = false;
    # };
    # homebrew-speedtest = {
    #   url = "github:teamookla/homebrew-speedtest";
    #   flake = false;
    # };
    # homebrew-hai = {
    #   url = "https://github.tools.sap/hAIperspace/hai-homebrew.git";
    #   flake = false;
    # };
    # homebrew-cline = {
    #   url = "github:cline/homebrew-cline";
    #   flake = false;
    # };
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