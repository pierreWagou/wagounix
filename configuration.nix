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

  nix = {
    enable = false;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      download-buffer-size = 524288000; # 500 MiB
    };
  };

  system = {
    stateVersion = 5;
    primaryUser = "I544489";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  users.users = {
    I544489 = {
      name = "I544489";
      home = "/Users/I544489";
    };
  };
}
