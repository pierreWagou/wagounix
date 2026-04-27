{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    podman-compose
  ];

  # All application services are managed by podman-compose.
  # Compose files live in the git repo at hosts/nixos/wagoulab/compose/,
  # cloned to /opt/wagounix on the server.
  # NixOS manages: Podman runtime, secrets (sops-nix), firewall, fail2ban,
  # hardware drivers, and per-service systemd units.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  imports = [
    ./secrets.nix
    ./compose.nix
    ./hardware-gpu.nix
    ./fail2ban.nix
    ./firewall.nix
  ];
}
