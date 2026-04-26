{ pkgs, host, ... }:

let
  port = host.homeAssistantPort;

  configFile = pkgs.writeText "home-assistant-configuration.yaml" ''
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

    frontend:
      themes: !include_dir_merge_named themes

    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml
  '';
in
{
  # OCI container exception: Home Assistant's ecosystem (HACS, custom integrations, add-ons)
  # assumes the Docker environment. Upstream only tests against their container image.
  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    volumes = [
      "/var/lib/home-assistant:/config"
      "${configFile}:/config/configuration.yaml:ro"
    ];
    environment = {
      TZ = "Europe/Paris";
    };
    ports = [ "127.0.0.1:${toString port}:8123" ];
    extraOptions = [ "--log-driver=journald" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0755 root root -"
  ];
}
