{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cloudflared
    ghostty.terminfo
  ];

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
