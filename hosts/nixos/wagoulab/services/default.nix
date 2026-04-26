{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
  ];

  # Service policy:
  # - Default to NixOS native services (module system, systemd, sops integration).
  # - OCI containers are exceptions for software that is impractical to run natively
  #   (e.g. upstream only tests Docker, ecosystem assumes container environment).
  #   Each container must document the justification in its service file.
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
