_: {
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/backup/vaultwarden";
    config = {
      DOMAIN = "https://vault.wagou.fr";
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      IP_HEADER = "X-Real-IP";
    };
  };
}
