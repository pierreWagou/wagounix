{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    podman-compose
  ];

  # All application services are managed by podman-compose (see compose/docker-compose.yml).
  # NixOS manages: Podman runtime, secrets (sops-nix), firewall, fail2ban, hardware drivers,
  # and the systemd service that runs podman-compose on boot.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  imports = [
    ./secrets.nix
    ./compose.nix
    ./cloudflared.nix
    ./hardware-gpu.nix
    ./adguardhome.nix
    ./fail2ban.nix
    ./firewall.nix
  ];
}
