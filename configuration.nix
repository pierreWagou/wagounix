{ config, lib, pkgs, ... }:

{

  imports = [
    ./settings/control-center.nix
    ./settings/dock.nix
    ./settings/global-domain.nix
    ./settings/finder.nix
    ./settings/screen-capture.nix
    ./settings/screen-saver.nix
    ./settings/software-update.nix
    ./settings/spaces.nix
    ./settings/trackpad.nix
  ];
  
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.enable = false;
  
  system.stateVersion = 5;

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  users.users= {
    I544489 = {
      name = "I544489";
      home = "/Users/I544489";
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

}
