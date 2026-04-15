{ host, ... }:

{
  imports = [
    ./settings
  ];

  # Nix daemon is managed externally by Lix installer.
  # Settings are in /etc/nix/nix.conf (managed by Lix, not nix-darwin).
  nix.enable = false;

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
