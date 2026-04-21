{
  config,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  # Vaultwarden — self-hosted password manager
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/backup/vaultwarden";
    config = {
      DOMAIN = "http://vault.home.local";
      SIGNUPS_ALLOWED = true;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      IP_HEADER = "X-Real-IP";
    };
  };

  # Caddy — reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts."http://vault.home.local".extraConfig = ''
      reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT} {
        header_up X-Real-IP {remote_host}
      }
    '';
  };

  # Open firewall for HTTP
  networking.firewall.allowedTCPPorts = [ 80 ];
}
