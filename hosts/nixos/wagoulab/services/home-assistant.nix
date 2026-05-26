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
      time_zone: ${host.timezone}
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
      image = "homeassistant/home-assistant:2026.5.4";
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/home-assistant:/config"
        "${configFile}:/config/configuration.yaml:ro"
      ];
      environments = {
        TZ = host.timezone;
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
    "d /var/lib/home-assistant/custom_components 0755 root root -"
  ];

  systemd.services.hacs-install = {
    description = "Install HACS into Home Assistant";
    wantedBy = [ "multi-user.target" ];
    after = [
      "home-assistant.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "home-assistant.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [ podman ];
    script = ''
      HACS_DIR="/var/lib/home-assistant/custom_components/hacs"
      if [ ! -d "$HACS_DIR" ]; then
        echo "Installing HACS via official script inside container..."
        podman exec home-assistant bash -c "wget -O - https://get.hacs.xyz | bash -"
        echo "HACS installed. Restarting Home Assistant..."
        systemctl restart home-assistant.service
      else
        echo "HACS already installed, skipping"
      fi
    '';
  };
}
