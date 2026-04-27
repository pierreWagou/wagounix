{ pkgs, host, ... }:

let
  port = host.immichPort;

  # Immich internal container network — allows server, ML, Postgres, and Redis to communicate
  networkName = "immich";

  # Common env vars shared between server and ML containers
  commonEnv = {
    DB_HOSTNAME = "immich-postgres";
    DB_PORT = "5432";
    DB_USERNAME = "postgres";
    DB_PASSWORD = "postgres";
    DB_DATABASE_NAME = "immich";
    REDIS_HOSTNAME = "immich-redis";
    REDIS_PORT = "6379";
  };
in
{
  # Create the Immich Podman network before containers start
  systemd.services.podman-network-immich = {
    description = "Create Immich Podman network";
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-immich-server.service"
      "podman-immich-ml.service"
      "podman-immich-postgres.service"
      "podman-immich-redis.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.podman}/bin/podman network exists ${networkName} || \
      ${pkgs.podman}/bin/podman network create ${networkName}
    '';
  };

  virtualisation.oci-containers.containers = {
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:release";
      ports = [ "127.0.0.1:${toString port}:2283" ];
      volumes = [
        "/var/lib/immich:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = commonEnv // {
        IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
      };
      dependsOn = [
        "immich-postgres"
        "immich-redis"
      ];
      extraOptions = [ "--network=${networkName}" ];
    };

    immich-ml = {
      image = "ghcr.io/immich-app/immich-machine-learning:release-openvino";
      volumes = [
        "/var/lib/immich-ml-cache:/cache"
      ];
      environment = commonEnv;
      # Intel GPU for ML acceleration (OpenVINO)
      extraOptions = [
        "--network=${networkName}"
        "--device=/dev/dri:/dev/dri"
        "--group-add=render"
      ];
    };

    immich-postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
      volumes = [
        "/var/lib/immich-postgres:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_PASSWORD = "postgres";
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      extraOptions = [
        "--network=${networkName}"
        "--shm-size=128m"
      ];
    };

    immich-redis = {
      image = "docker.io/valkey/valkey:9";
      extraOptions = [ "--network=${networkName}" ];
    };
  };

  # Host GPU drivers (shared with Jellyfin)
  hardware.graphics.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/immich 0755 root root -"
    "d /var/lib/immich-ml-cache 0755 root root -"
    "d /var/lib/immich-postgres 0755 root root -"
  ];
}
