{ config, host, ... }:

{
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/backup/vaultwarden";
    environmentFile = config.sops.templates."vaultwarden.env".path;
    config = {
      DOMAIN = "https://vault.${host.domain}";
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      IP_HEADER = "X-Real-IP";
    };
  };

  systemd.services.vaultwarden.restartTriggers = [
    config.sops.templates."vaultwarden.env".content
  ];
}
