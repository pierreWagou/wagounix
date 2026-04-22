{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    docker-compose
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
    ./fail2ban.nix
    ./firewall.nix
  ];
}
