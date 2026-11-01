_: {

  # All application services run as Podman containers via quadlet-nix.
  # NixOS manages: Podman runtime, container definitions, secrets (sops-nix),
  # firewall, fail2ban, and hardware drivers.
  # Single deploy: nixos-rebuild switch. Atomic rollback: nixos-rebuild --rollback.
  imports = [
    ./podman.nix
    ./secrets.nix
    ./traefik
    ./cloudflared
    ./vaultwarden
    ./jellyfin
    ./home-assistant
    ./homepage
    ./adguardhome
    ./immich
    ./fail2ban.nix
    ./firewall.nix
    ./tailscale.nix
    ./ttyd.nix
    ./rbw.nix
    ./webhook
    ./renovate
    ./kitchenowl
    ./authentik
    ./seafile
    ./onlyoffice
    ./penpot
    ./branding.nix
    ./dokploy
    ./stalwart
    ./satisfactory.nix
    ./omnigent
  ];
}
