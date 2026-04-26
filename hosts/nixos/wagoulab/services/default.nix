{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
  ];

  # All OCI containers use Docker as the backend
  virtualisation.oci-containers.backend = "docker";

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
