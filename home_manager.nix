{ inputs, config, lib, pkgs, ... }: {

  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.I544489 = {
    imports = [
      ./users/I544489/home.nix
      inputs.catppuccin.homeModules.catppuccin
    ];
  };
}
