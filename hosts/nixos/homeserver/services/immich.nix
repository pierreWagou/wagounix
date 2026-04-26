{ config, ... }:

let
  immichVersion = "release";
  immichNetwork = "immich";

  # Ensure each Immich container starts after the shared Docker network is created
  afterNetwork = {
    after = [ "immich-network.service" ];
    requires = [ "immich-network.service" ];
  };
in
{
  virtualisation.oci-containers.containers = {
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:${immichVersion}";
      ports = [ "127.0.0.1:2283:2283" ];
      volumes = [
        "/var/lib/immich/upload:/usr/src/app/upload"
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
        "--network=${immichNetwork}"
        "--device=/dev/dri/renderD128:/dev/dri/renderD128"
      ];
    };

    immich-ml = {
      image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
      volumes = [
        "/var/lib/immich/model-cache:/cache"
      ];
      extraOptions = [
        "--network=${immichNetwork}"
      ];
    };

    immich-postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
      volumes = [
        "/var/lib/immich/db:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_USER = "immich";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      environmentFiles = [
        config.sops.templates."immich-db.env".path
      ];
      extraOptions = [
        "--network=${immichNetwork}"
        "--shm-size=128m"
      ];
    };

    immich-redis = {
      image = "docker.io/valkey/valkey:9";
      extraOptions = [
        "--network=${immichNetwork}"
      ];
    };
  };

  systemd.services = {
    # Create the shared Docker network for the Immich stack
    immich-network = {
      description = "Create Immich Docker network";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "/run/current-system/sw/bin/docker network create ${immichNetwork} || true";
        ExecStop = "/run/current-system/sw/bin/docker network rm ${immichNetwork} || true";
      };
    };

    # Ensure Immich containers start after the network is created
    docker-immich-server = afterNetwork;
    docker-immich-ml = afterNetwork;
    docker-immich-postgres = afterNetwork;
    docker-immich-redis = afterNetwork;
  };

  # GPU support for hardware transcoding
  hardware.graphics.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/immich 0755 root root -"
    "d /var/lib/immich/upload 0755 root root -"
    "d /var/lib/immich/db 0755 root root -"
    "d /var/lib/immich/model-cache 0755 root root -"
  ];
}
