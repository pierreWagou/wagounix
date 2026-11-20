{ host, ... }:

{
  # Daemon owned by the external Nix installer (/etc/nix/nix.conf), not nix-darwin.
  nix.enable = false;

  system = {
    stateVersion = 5;
    primaryUser = host.username;
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
}
