{ host, ... }:

{
  # Nix daemon is managed externally by Lix installer.
  # Settings are in /etc/nix/nix.conf (managed by Lix, not nix-darwin).
  nix.enable = false;

  system = {
    stateVersion = 5;
    primaryUser = host.username;
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Homeserver local DNS resolution
  environment.etc.hosts.text = ''
    127.0.0.1       localhost
    255.255.255.255 broadcasthost
    ::1             localhost
    192.168.68.65   vault.home.local
  '';
}
