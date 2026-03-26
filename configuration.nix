{ host, ... }:

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
  };
}
