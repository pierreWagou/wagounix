{ host, lib, pkgs, ... }:

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
    primaryUser = host.username;
  };

  users.users = {
    ${host.username} = {
      name = host.username;
      home = "/Users/${host.username}";
    };
  };
  
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
    # text = lib.mkForce (lib.concatLines [
    #   "auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so"
    #   "auth       sufficient     pam_tid.so.2"
    # ]);
  };
}
