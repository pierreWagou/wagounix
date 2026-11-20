_: {

  imports = [
    ./podman.nix
    ./secrets.nix
    ./traefik
    ./cloudflared
    ./vaultwarden
    ./jellyfin
    ./home-assistant
    ./mosquitto
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
    ./firecrawl
    ./onlyoffice
    ./branding.nix
    ./dokploy
    ./stalwart
    ./satisfactory.nix
    ./omnigent
  ];
}
