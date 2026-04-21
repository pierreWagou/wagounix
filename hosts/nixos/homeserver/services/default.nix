{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    docker-compose
    ghostty.terminfo
  ];

  imports = [
    ./vaultwarden.nix
    ./caddy.nix
    ./adguardhome.nix
    ./cloudflared.nix
    ./immich.nix
    ./firewall.nix
  ];
}
