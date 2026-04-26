{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab.opencloud;
in
{
  options.homelab.opencloud = {
    enable = lib.mkEnableOption "OpenCloud file sync (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9200;
      description = "Host port for OpenCloud";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Full domain name (e.g. cloud.wagou.fr)";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/opencloud";
      description = "Host path for persistent data";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.opencloud = {
      image = "opencloudeu/opencloud-rolling:latest";
      ports = [ "127.0.0.1:${toString cfg.port}:9200" ];
      volumes = [
        "${cfg.dataDir}/config:/etc/opencloud"
        "${cfg.dataDir}/data:/var/lib/opencloud"
      ];
      environment = {
        OC_URL = "https://${cfg.domain}";
        OC_INSECURE = "true";
        PROXY_TLS = "false";
        IDM_CREATE_DEMO_USERS = "false";
        PROXY_ENABLE_BASIC_AUTH = "true";
      };
      environmentFiles = [
        config.sops.templates."opencloud.env".path
      ];
      # First boot: init generates internal secrets, then start the server.
      # Subsequent boots: init is a no-op (|| true), server starts normally.
      entrypoint = "/bin/sh";
      cmd = [
        "-c"
        "opencloud init || true; opencloud server"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 1000 1000 -"
      "d ${cfg.dataDir}/config 0755 1000 1000 -"
      "d ${cfg.dataDir}/data 0755 1000 1000 -"
    ];
  };
}
