{ pkgs, host, ... }:

let
  initialConfig = pkgs.writeText "home-assistant-initial-config" ''
    default_config:

    homeassistant:
      name: Home
      unit_system: metric
      time_zone: Europe/Paris
      external_url: https://home.${host.domain}
      internal_url: https://home.${host.domain}

    http:
      use_x_forwarded_for: true
      trusted_proxies:
        - 172.16.0.0/12
  '';
in
{
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    volumes = [ "/var/lib/home-assistant:/config" ];
    environment = {
      TZ = "Europe/Paris";
    };
    ports = [ "127.0.0.1:8123:8123" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0755 root root -"
  ];

  # Seed configuration.yaml on first boot (won't overwrite if it already exists)
  system.activationScripts.home-assistant-config = ''
    if [ ! -f /var/lib/home-assistant/configuration.yaml ]; then
      cp ${initialConfig} /var/lib/home-assistant/configuration.yaml
    fi
  '';
}
