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
      # Run speed test once per day at 3:00 AM
      SPEEDTEST_SCHEDULE = "0 3 * * *";
      APP_URL = "https://speed.${host.domain}";
    };
  };

  # Ensure data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/speedtest-tracker 0755 1000 1000 -"
  ];
}
