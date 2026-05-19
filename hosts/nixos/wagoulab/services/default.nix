{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
  ];

  # All application services run as Podman containers via quadlet-nix.
  # NixOS manages: Podman runtime, container definitions, secrets (sops-nix),
  # firewall, fail2ban, and hardware drivers.
  # Single deploy: nixos-rebuild switch. Atomic rollback: nixos-rebuild --rollback.
  imports = [
    ./podman.nix
    ./secrets.nix
    ./traefik.nix
    ./cloudflared.nix
    ./vaultwarden.nix
    ./opencloud.nix
    ./jellyfin.nix
    ./home-assistant.nix
    ./homepage.nix
    ./adguardhome.nix
    ./immich.nix
    ./fail2ban.nix
    ./firewall.nix
    ./tailscale.nix
    ./ttyd.nix
    ./rbw.nix
  ];
}
