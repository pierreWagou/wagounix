{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;

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
        - 10.89.0.0/16

    frontend:
      themes: !include_dir_merge_named themes

    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml
  '';
in
{
  virtualisation.quadlet.containers.home-assistant = {
    containerConfig = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/home-assistant:/config"
        "${configFile}:/config/configuration.yaml:ro"
      ];
      environments = {
        TZ = "Europe/Paris";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.homeassistant.rule" = "Host(`home.${host.domain}`)";
        "traefik.http.routers.homeassistant.entrypoints" = "websecure";
        "traefik.http.routers.homeassistant.tls" = "true";
        "traefik.http.routers.homeassistant.middlewares" = "secure-headers@file";
        "traefik.http.services.homeassistant.loadbalancer.server.port" = "8123";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0755 root root -"
  ];
}
