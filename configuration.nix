{ pkgs, ... }:

{
  imports = [
    ./settings
  ];

  nix = {
    enable = false;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      download-buffer-size = 524288000;
    };
  };

  system = {
    stateVersion = 5;
    primaryUser = "I544489";
  };

  system.activationScripts.customIcons.deps = [ "homebrew" ];
  
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  users.users = {
    I544489 = {
      name = "I544489";
      home = "/Users/I544489";
    };
  };
}
