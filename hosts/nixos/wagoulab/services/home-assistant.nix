{
  pkgs,
  host,
  config,
  ...
}:

let
  heatmapDashboard = ./dashboards/heatmap.yaml;
  devicesDashboard = ./dashboards/devices.yaml;

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
    ${builtins.concatStringsSep "\n" (map (cidr: "        - ${cidr}") host.podmanCIDRs)}

        frontend:
          themes: !include_dir_merge_named themes

        lovelace:
          dashboards:
            heatmap-weather:
              mode: yaml
              title: Heatmap
              icon: mdi:home-thermometer
              show_in_sidebar: true
              require_admin: false
              filename: dashboards/heatmap.yaml
            devices-weather:
              mode: yaml
              title: Devices
              icon: mdi:devices
              show_in_sidebar: true
              require_admin: false
              filename: dashboards/devices.yaml

        automation: !include automations.yaml
        script: !include scripts.yaml
        scene: !include scenes.yaml

        auth_oidc:
          client_id: "B5xh86aOL0cHkNRHze8iA1HsDtZpwWSjmVL8j2K7"
          client_secret: !secret oidc_client_secret
          discovery_url: "https://auth.wagou.fr/application/o/home-assistant/.well-known/openid-configuration"
          features:
            automatic_user_linking: true
            automatic_person_creation: true
            default_redirect: true
          roles:
            admin: "admins"
  '';
in
{
  virtualisation.quadlet.containers.home-assistant = {
    containerConfig = {
      image = "homeassistant/home-assistant:2026.5.4";
      networks = [ "host" ];
      volumes = [
        "/var/lib/home-assistant:/config"
        "${configFile}:/config/configuration.yaml:ro"
        "${config.sops.templates."ha-secrets.yaml".path}:/config/secrets.yaml:ro"
        "${heatmapDashboard}:/config/dashboards/heatmap.yaml:ro"
        "${devicesDashboard}:/config/dashboards/devices.yaml:ro"
      ];
      environments = {
        TZ = host.timezone;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0755 root root -"
    "d /var/lib/home-assistant/custom_components 0755 root root -"
    "d /var/lib/home-assistant/dashboards 0755 root root -"
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
      set -euo pipefail
      HACS_DIR="/var/lib/home-assistant/custom_components/hacs"
      if [ ! -d "$HACS_DIR" ]; then
        echo "Installing HACS via official script inside container..."
        # TODO: Pin HACS to a specific release and verify checksum.
        # Current approach fetches and executes an unpinned remote script (supply chain risk).
        podman exec home-assistant bash -c "wget -O - https://get.hacs.xyz | bash -"
        echo "HACS installed. Restarting Home Assistant..."
        systemctl restart home-assistant.service
      else
        echo "HACS already installed, skipping"
      fi
    '';
  };
}
