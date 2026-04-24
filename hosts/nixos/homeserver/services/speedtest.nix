{ host, ... }:

{
  # Speedtest Tracker — periodic internet speed tests
  virtualisation.oci-containers.containers.speedtest-tracker = {
    image = "ghcr.io/alexjustesen/speedtest-tracker:latest";
    ports = [ "127.0.0.1:8765:80" ];
    volumes = [
      "/var/lib/speedtest-tracker:/config"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Europe/Paris";
      DB_CONNECTION = "sqlite";
      DB_DATABASE = "/config/database.sqlite";
      SPEEDTEST_SCHEDULE = "0 3 * * *";
      APP_URL = "https://speed.${host.domain}";
    };
  };

  # Ensure data directory and SQLite database exist
  systemd.tmpfiles.rules = [
    "d /var/lib/speedtest-tracker 0755 1000 1000 -"
    "f /var/lib/speedtest-tracker/database.sqlite 0644 1000 1000 -"
  ];
}
