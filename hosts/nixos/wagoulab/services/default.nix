{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
  ];

  # Service policy:
  # - Application services run as Podman OCI containers.
  # - Infrastructure services (Caddy, Cloudflared, Fail2ban, Firewall) stay native
  #   because they need direct host network/filesystem access.
  # - Secrets are managed by sops-nix on the host and mounted into containers.
  virtualisation.oci-containers.backend = "podman";

  virtualisation.podman = {
    dockerCompat = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  imports = [
    ./secrets.nix
    ./vaultwarden.nix
    ./caddy.nix
    ./adguardhome.nix
    ./cloudflared.nix
    ./immich.nix
    ./opencloud.nix
    ./homepage.nix
    ./home-assistant.nix
    ./jellyfin.nix
    ./fail2ban.nix
    ./firewall.nix
  ];
}
