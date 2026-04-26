{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab.immich;
  network = "immich";

  afterNetwork = {
    after = [ "immich-network.service" ];
    requires = [ "immich-network.service" ];
  };
in
{
  options.homelab.immich = {
    enable = lib.mkEnableOption "Immich photo management (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 2283;
      description = "Host port for Immich web UI";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/immich";
      description = "Host path for persistent data (uploads, db, model cache)";
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "release";
      description = "Immich image tag";
    };
    accelerationDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/dev/dri/renderD128";
      description = "GPU device for hardware transcoding (null to disable)";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      immich-server = {
        image = "ghcr.io/immich-app/immich-server:${cfg.version}";
        ports = [ "127.0.0.1:${toString cfg.port}:2283" ];
        volumes = [
          "${cfg.dataDir}/upload:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environment = {
          DB_HOSTNAME = "immich-postgres";
          DB_USERNAME = "immich";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "immich-redis";
        };
        environmentFiles = [
          config.sops.templates."immich.env".path
        ];
        dependsOn = [
          "immich-postgres"
          "immich-redis"
        ];
        extraOptions = [
          "--network=${network}"
        ]
        ++ lib.optionals (cfg.accelerationDevice != null) [
          "--device=${cfg.accelerationDevice}:${cfg.accelerationDevice}"
        ];
      };

      immich-ml = {
        image = "ghcr.io/immich-app/immich-machine-learning:${cfg.version}";
        volumes = [ "${cfg.dataDir}/model-cache:/cache" ];
        extraOptions = [ "--network=${network}" ];
      };

      immich-postgres = {
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
        volumes = [ "${cfg.dataDir}/db:/var/lib/postgresql/data" ];
        environment = {
          POSTGRES_USER = "immich";
          POSTGRES_DB = "immich";
          POSTGRES_INITDB_ARGS = "--data-checksums";
        };
        environmentFiles = [
          config.sops.templates."immich-db.env".path
        ];
        extraOptions = [
          "--network=${network}"
          "--shm-size=128m"
        ];
      };

      immich-redis = {
        image = "docker.io/valkey/valkey:9";
        extraOptions = [ "--network=${network}" ];
      };
    };

    systemd.services = {
      immich-network = {
        description = "Create Immich Docker network";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = "/run/current-system/sw/bin/docker network create ${network} || true";
        preStop = "/run/current-system/sw/bin/docker network rm ${network} || true";
      };

      docker-immich-server = afterNetwork;
      docker-immich-ml = afterNetwork;
      docker-immich-postgres = afterNetwork;
      docker-immich-redis = afterNetwork;
    };

    hardware.graphics.enable = true;

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
      "d ${cfg.dataDir}/upload 0755 root root -"
      "d ${cfg.dataDir}/db 0755 root root -"
      "d ${cfg.dataDir}/model-cache 0755 root root -"
    ];
  };
}
