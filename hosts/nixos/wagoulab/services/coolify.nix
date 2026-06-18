{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
  coolifyVersion = "4.0.0-beta.425";
in
{
  virtualisation = {
    # Expose the Podman socket at /var/run/docker.sock so Coolify can manage containers.
    podman.dockerSocket.enable = true;

    quadlet = {
      # Coolify-internal network — isolates DB and Redis from the proxy network.
      networks.coolify-internal = { };

      containers = {
        coolify = {
          containerConfig = {
            image = "ghcr.io/coollabsio/coolify:${coolifyVersion}";
            noNewPrivileges = true;
            networks = [
              networks.proxy.ref
              networks.coolify-internal.ref
            ];
            environments = {
              APP_ENV = "production";
              APP_DEBUG = "false";
              DB_CONNECTION = "pgsql";
              DB_HOST = "coolify-db";
              DB_PORT = "5432";
              DB_DATABASE = "coolify";
              DB_USERNAME = "coolify";
              REDIS_HOST = "coolify-redis";
              REDIS_PORT = "6379";
              SSL_MODE = "off";
              # Disable Coolify's built-in Traefik — routing is handled by the existing Traefik instance.
              DISABLE_TRAEFIK_USAGE = "true";
              PUSHER_HOST = "coolify-realtime";
              PUSHER_PORT = "6001";
              PUSHER_SCHEME = "http";
            };
            environmentFiles = [ config.sops.templates."coolify.env".path ];
            volumes = [
              "/data/coolify:/data/coolify"
              "/var/run/docker.sock:/var/run/docker.sock"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.coolify.rule" = "Host(`coolify.${host.domain}`)";
              "traefik.http.routers.coolify.entrypoints" = "websecure";
              "traefik.http.routers.coolify.tls" = "true";
              "traefik.http.routers.coolify.middlewares" = "secure-headers@file";
              "traefik.http.services.coolify.loadbalancer.server.port" = "8000";
            };
          };
        };

        coolify-realtime = {
          containerConfig = {
            image = "ghcr.io/coollabsio/coolify-realtime:1.0.5";
            noNewPrivileges = true;
            networks = [ networks.coolify-internal.ref ];
            environmentFiles = [ config.sops.templates."coolify.env".path ];
          };
        };

        coolify-db = {
          containerConfig = {
            image = "docker.io/library/postgres:15-alpine";
            noNewPrivileges = true;
            networks = [ networks.coolify-internal.ref ];
            volumes = [ "/data/coolify/db:/var/lib/postgresql/data" ];
            environments = {
              POSTGRES_DB = "coolify";
              POSTGRES_USER = "coolify";
            };
            environmentFiles = [ config.sops.templates."coolify-db.env".path ];
          };
        };

        coolify-redis = {
          containerConfig = {
            image = host.valkeyImage;
            noNewPrivileges = true;
            networks = [ networks.coolify-internal.ref ];
            exec = [
              "--save"
              "60"
              "1"
              "--loglevel"
              "warning"
              "--include"
              "/etc/valkey/valkey.conf"
            ];
            volumes = [
              "/data/coolify/redis:/data"
              "${config.sops.templates."coolify-valkey.conf".path}:/etc/valkey/valkey.conf:ro"
            ];
          };
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/coolify 0750 root root -"
    "d /data/coolify/db 0750 root root -"
    "d /data/coolify/redis 0750 root root -"
    "d /data/coolify/ssh 0700 root root -"
    "d /data/coolify/ssh/keys 0700 root root -"
    "d /data/coolify/applications 0750 root root -"
    "d /data/coolify/databases 0750 root root -"
    "d /data/coolify/backups 0750 root root -"
    "d /data/coolify/services 0750 root root -"
    "d /data/coolify/proxy 0750 root root -"
  ];
}
