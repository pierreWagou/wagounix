{
  pkgs,
  host,
  config,
  ...
}:

let
  ws = import ../lib/web-service.nix { inherit config host; };

  # Single source of truth for Lovelace dashboards: drives the
  # `lovelace.dashboards` section of configuration.yaml AND the volume mounts.
  dashboards = {
    heatmap-weather = {
      title = "Heatmap";
      icon = "mdi:home-thermometer";
      file = ./dashboards/heatmap.yaml;
    };
    devices-weather = {
      title = "Devices";
      icon = "mdi:devices";
      file = ./dashboards/devices.yaml;
    };
    hue-lights = {
      title = "Lights";
      icon = "mdi:lightbulb";
      file = ./dashboards/lights.yaml;
    };
    miette-pets = {
      title = "Miette";
      icon = "mdi:cat";
      file = ./dashboards/miette.yaml;
    };
    plant-monitor = {
      title = "Plants";
      icon = "mdi:flower";
      file = ./dashboards/plants.yaml;
    };
    shutters-panel = {
      title = "Shutters";
      icon = "mdi:window-shutter-open";
      file = ./dashboards/shutters.yaml;
    };
  };

  # NOTE: entries carry explicit leading spaces (double-quoted strings have no
  # indent stripping) and the interpolation below sits at column 0, so the
  # block lands nested under `dashboards:`.
  lovelaceDashboards = builtins.concatStringsSep "\n" (
    builtins.attrValues (
      builtins.mapAttrs (
        name: d:
        "            ${name}:\n              mode: yaml\n              title: ${d.title}\n              icon: ${d.icon}\n              show_in_sidebar: true\n              require_admin: false\n              filename: dashboards/${baseNameOf d.file}"
      ) dashboards
    )
  );

  dashboardVolumes = builtins.attrValues (
    builtins.mapAttrs (_: d: "${d.file}:/config/dashboards/${baseNameOf d.file}:ro") dashboards
  );

  # HACS pinned to a release tarball (hash-verified by Nix at build time).
  # Seeded into the stateful custom_components dir before every start —
  # same pattern as the Seafile seed. No remote pipe-to-bash, no restart dance.
  # NOTE: HACS is merging into Home Assistant as built-in Marketplace from
  # HA 2026.11 — this whole seed can go away once we upgrade past that.
  hacsVersion = "2.0.5";
  hacsZip = pkgs.fetchurl {
    url = "https://github.com/hacs/integration/releases/download/${hacsVersion}/hacs.zip";
    hash = "sha256-l75rgkpPOOaDcozG3XI2f2uLrQpDQosbO5h6MIet9BM=";
  };

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
          ${builtins.concatStringsSep "\n      " (map (cidr: "- ${cidr}") host.podmanCIDRs)}

        frontend:
          themes: !include_dir_merge_named themes

        lovelace:
          dashboards:
    ${lovelaceDashboards}
        automation: !include automations.yaml
        script: !include scripts.yaml
        scene: !include scenes.yaml

        auth_oidc:
          client_id: "B5xh86aOL0cHkNRHze8iA1HsDtZpwWSjmVL8j2K7"
          client_secret: !secret oidc_client_secret
          discovery_url: "https://auth.${host.domain}/application/o/home-assistant/.well-known/openid-configuration"
          features:
            automatic_user_linking: false
            automatic_person_creation: true
            default_redirect: true
          roles:
            admin: "admins"
  '';
  ha = ws.mkWebService {
    name = "home-assistant";
    exposeViaTraefik = false; # routed via Traefik file provider (host network has no container discovery)
    networks = [ "host" ];
    image = "docker.io/homeassistant/home-assistant:2026.8.3";
    env = {
      TZ = host.timezone;
    };
    volumes = [
      "/var/lib/home-assistant:/config"
      "${configFile}:/config/configuration.yaml:ro"
      "${config.sops.templates."ha-secrets.yaml".path}:/config/secrets.yaml:ro"
    ]
    ++ dashboardVolumes
    ++ [ "/run/dbus/system_bus_socket:/run/dbus/system_bus_socket:ro" ];
    dataDirs = [
      "/var/lib/home-assistant"
      "/var/lib/home-assistant/custom_components"
      "/var/lib/home-assistant/dashboards"
    ];
  };
in
{
  sops = {
    secrets = {
      oidc-client-secret = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "ha-secrets.yaml" = {
        content = "oidc_client_secret: ${config.sops.placeholder.oidc-client-secret}\n";
      };
    };
  };

  virtualisation.quadlet.containers.home-assistant.containerConfig = ha.containerConfig;

  systemd = {
    tmpfiles.rules = ha.tmpfilesRules;

    # Seed pinned HACS before every start. Convergent: reinstalls only when
    # the version marker differs, so bumping hacsVersion applies on next start.
    services.home-assistant.serviceConfig.ExecStartPre = [
      (pkgs.writeShellScript "home-assistant-hacs-seed" ''
        set -euo pipefail
        CUSTOM_COMPONENTS="/var/lib/home-assistant/custom_components"
        HACS_DIR="$CUSTOM_COMPONENTS/hacs"
        MARKER="$CUSTOM_COMPONENTS/.hacs-pinned-version"
        if [ ! -d "$HACS_DIR" ] || [ ! -f "$MARKER" ] || [ "$(cat "$MARKER")" != "${hacsVersion}" ]; then
          echo "seeding HACS ${hacsVersion}..."
          rm -rf "$HACS_DIR"
          mkdir -p "$CUSTOM_COMPONENTS"
          ${pkgs.unzip}/bin/unzip -o -q ${hacsZip} -d "$HACS_DIR"
          echo -n "${hacsVersion}" > "$MARKER"
        fi
      '')
    ];
  };
}
