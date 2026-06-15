_: {

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
    ./jellyfin.nix
    ./home-assistant.nix
    ./homepage
    ./adguardhome.nix
    ./immich.nix
    ./fail2ban.nix
    ./firewall.nix
    ./tailscale.nix
    ./ttyd.nix
    ./rbw.nix
    ./creneau.nix
    ./webhook.nix
    ./renovate.nix
    ./kitchenowl.nix
    ./authentik
    ./seafile
    ./branding.nix
  ];
}
