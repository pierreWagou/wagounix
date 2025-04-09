{
  description = "SAP nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ... }: {
    darwinConfigurations = {
      sap = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.I544489 = import ./home.nix;
          }
        ];
      };
    };
  };
}
#     configuration = { pkgs, ... }: {
#       # List packages installed in system profile. To search by name, run:
#       # $ nix-env -qaP | grep wget
#       environment.systemPackages =
#         [ pkgs.vim
#           pkgs.bruno
#         ];

#       # Necessary for using flakes on this system.
#       nix.settings.experimental-features = "nix-command flakes";

#       # Enable alternative shell support in nix-darwin.
#       # programs.fish.enable = true;

#       # Set Git commit hash for darwin-version.
#       system.configurationRevision = self.rev or self.dirtyRev or null;

#       # Used for backwards compatibility, please read the changelog before changing.
#       # $ darwin-rebuild changelog
#       system.stateVersion = 6;

#       # The platform the configuration will be used on.
#       nixpkgs.hostPlatform = "aarch64-darwin";
#     };
#   in
#   {
#     # Build darwin flake using:
#     # $ darwin-rebuild build --flake .#simple
#     darwinConfigurations."sap" = nix-darwin.lib.darwinSystem {
#       modules = [ configuration ];
#     };
#   };
# }
