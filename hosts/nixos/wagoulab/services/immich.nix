{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks containers;
  immichVersion = "v2.7.5";
in
{
  # Immich-internal network for DB, Redis, and ML (not exposed to Traefik)
  virtualisation.quadlet.networks.immich-internal = { };

  virtualisation.quadlet.containers = {
    immich-server = {
      containerConfig = {
        image = "ghcr.io/immich-app/immich-server:${immichVersion}";
        noNewPrivileges = true;
        networks = [
          networks.proxy.ref
          networks.immich-internal.ref
        ];
        volumes = [
          "/var/lib/immich:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environments = {
          DB_HOSTNAME = "immich-postgres";
          DB_PORT = "5432";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "immich-redis";
          REDIS_PORT = "6379";
          IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
        };
        environmentFiles = [ config.sops.templates."immich.env".path ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.immich.rule" = "Host(`pixel.${host.domain}`)";
          "traefik.http.routers.immich.entrypoints" = "websecure";
          "traefik.http.routers.immich.tls" = "true";
          "traefik.http.routers.immich.middlewares" = "secure-headers@file";
          "traefik.http.services.immich.loadbalancer.server.port" = "2283";
        };
      };
      unitConfig = {
        Requires = [
          containers.immich-postgres.ref
          containers.immich-redis.ref
        ];
        After = [
          containers.immich-postgres.ref
          containers.immich-redis.ref
        ];
      };
    };

    immich-ml = {
      containerConfig = {
        image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}-openvino";
        noNewPrivileges = true;
        networks = [ networks.immich-internal.ref ];
        volumes = [ "/var/lib/immich-ml-cache:/cache" ];
        devices = [ "/dev/dri:/dev/dri" ];
        addGroups = [ host.renderGroupGid ]; # render group GID on NixOS (also in jellyfin.nix)
      };
    };

    immich-postgres = {
      containerConfig = {
        image = "ghcr.io/immich-app/postgres:16-vectorchord0.4.3-pgvectors0.2.0";
        noNewPrivileges = true;
        networks = [ networks.immich-internal.ref ];
        volumes = [ "/var/lib/immich-postgres:/var/lib/postgresql/data" ];
        environments = {
          POSTGRES_DB = "immich";
          POSTGRES_INITDB_ARGS = "--data-checksums";
        };
        environmentFiles = [ config.sops.templates."immich-postgres.env".path ];
        shmSize = "128m";
      };
    };

    immich-redis = {
      containerConfig = {
        image = host.valkeyImage;
        noNewPrivileges = true;
        networks = [ networks.immich-internal.ref ];
        exec = [
          "--save"
          "60"
          "1"
          "--loglevel"
          "warning"
        ];
        volumes = [ "/var/lib/immich-redis:/data" ];
      };
    };
  };

  # GPU drivers shared with Jellyfin — primary declaration is in jellyfin.nix
  hardware.graphics.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/immich 0755 root root -"
    "d /var/lib/immich-ml-cache 0755 root root -"
    "d /var/lib/immich-postgres 0755 root root -"
    "d /var/lib/immich-redis 0755 root root -"
  ];
}
