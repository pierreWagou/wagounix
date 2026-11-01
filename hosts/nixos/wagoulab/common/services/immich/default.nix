{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks containers;
  ws = import ../lib/web-service.nix { inherit config host; };
  immichVersion = "v2.7.5";
  server = ws.mkWebService {
    name = "immich";
    subdomain = "pixel";
    image = "ghcr.io/immich-app/immich-server:${immichVersion}";
    port = 2283;
    env = {
      DB_HOSTNAME = "immich-postgres";
      DB_PORT = "5432";
      DB_DATABASE_NAME = "immich";
      REDIS_HOSTNAME = "immich-redis";
      REDIS_PORT = "6379";
      IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
    };
    volumes = [
      "/var/lib/immich:/usr/src/app/upload"
      "/etc/localtime:/etc/localtime:ro"
    ];
    environmentFiles = [ config.sops.templates."immich.env".path ];
    extraNetworks = [ networks.immich-internal.ref ];
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
in
{
  sops = {
    secrets = {
      immich-db-username = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };

      immich-db-password = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };

      immich-api-key = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "immich.env" = {
        content = builtins.concatStringsSep "\n" [
          "DB_USERNAME=${config.sops.placeholder.immich-db-username}"
          "DB_PASSWORD=${config.sops.placeholder.immich-db-password}"
        ];
      };

      "immich-postgres.env" = {
        content = builtins.concatStringsSep "\n" [
          "POSTGRES_USER=${config.sops.placeholder.immich-db-username}"
          "POSTGRES_PASSWORD=${config.sops.placeholder.immich-db-password}"
        ];
      };
    };
  };

  # Immich-internal network for DB, Redis, and ML (not exposed to Traefik)
  virtualisation.quadlet.networks.immich-internal = { };

  virtualisation.quadlet.containers = {
    immich-server.containerConfig = server.containerConfig;
    immich-server.unitConfig = server.unitConfig;

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
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
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
    "d /var/lib/immich-redis 0755 999 999 -"
  ];
}
