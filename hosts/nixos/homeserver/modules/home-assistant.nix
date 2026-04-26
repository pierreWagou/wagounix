{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab.home-assistant;

  configFile = pkgs.writeText "home-assistant-configuration.yaml" ''
    default_config:

    homeassistant:
      name: Home
      unit_system: metric
      time_zone: ${cfg.timeZone}
      external_url: https://${cfg.domain}
      internal_url: https://${cfg.domain}

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
  options.homelab.home-assistant = {
    enable = lib.mkEnableOption "Home Assistant (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8123;
      description = "Host port for Home Assistant";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Full domain name (e.g. home.wagou.fr)";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/home-assistant";
      description = "Host path for persistent data";
    };
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Paris";
      description = "Time zone for Home Assistant";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      ports = [ "127.0.0.1:${toString cfg.port}:8123" ];
      volumes = [
        "${cfg.dataDir}:/config"
        "${configFile}:/config/configuration.yaml:ro"
      ];
      environment = {
        TZ = cfg.timeZone;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];
  };
}
