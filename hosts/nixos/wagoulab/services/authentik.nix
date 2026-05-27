{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
  authentikVersion = "2026.5.0";
in
{
  # Authentik-internal network for DB and Redis (not exposed to Traefik)
  virtualisation.quadlet.networks.authentik-internal = { };

  virtualisation.quadlet.containers = {
    authentik-server = {
      containerConfig = {
        image = "ghcr.io/goauthentik/server:${authentikVersion}";
        noNewPrivileges = true;
        networks = [
          networks.proxy.ref
          networks.authentik-internal.ref
        ];
        environments = {
          AUTHENTIK_REDIS__HOST = "authentik-redis";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
        };
        environmentFiles = [ config.sops.templates."authentik.env".path ];
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/templates:/templates"
        ];
        exec = [ "server" ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.authentik.rule" = "Host(`cipher.${host.domain}`)";
          "traefik.http.routers.authentik.entrypoints" = "websecure";
          "traefik.http.routers.authentik.tls" = "true";
          "traefik.http.routers.authentik.middlewares" = "secure-headers@file";
          "traefik.http.services.authentik.loadbalancer.server.port" = "9000";
        };
      };
    };

    authentik-worker = {
      containerConfig = {
        image = "ghcr.io/goauthentik/server:${authentikVersion}";
        noNewPrivileges = true;
        networks = [ networks.authentik-internal.ref ];
        environments = {
          AUTHENTIK_REDIS__HOST = "authentik-redis";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
        };
        environmentFiles = [ config.sops.templates."authentik.env".path ];
        volumes = [
          "/var/lib/authentik/media:/media"
          "/var/lib/authentik/templates:/templates"
        ];
        exec = [ "worker" ];
      };
    };

    authentik-postgres = {
      containerConfig = {
        image = "docker.io/library/postgres:16-alpine";
        noNewPrivileges = true;
        networks = [ networks.authentik-internal.ref ];
        volumes = [ "/var/lib/authentik-postgres:/var/lib/postgresql/data" ];
        environments = {
          POSTGRES_DB = "authentik";
          POSTGRES_USER = "authentik";
        };
        environmentFiles = [ config.sops.templates."authentik-postgres.env".path ];
      };
    };

    authentik-redis = {
      containerConfig = {
        image = "docker.io/valkey/valkey:9.1.0";
        noNewPrivileges = true;
        networks = [ networks.authentik-internal.ref ];
        exec = [
          "--save"
          "60"
          "1"
          "--loglevel"
          "warning"
        ];
        volumes = [ "/var/lib/authentik-redis:/data" ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/authentik 0755 root root -"
    "d /var/lib/authentik/media 0755 root root -"
    "d /var/lib/authentik/templates 0755 root root -"
    "d /var/lib/authentik-postgres 0755 root root -"
    "d /var/lib/authentik-redis 0755 root root -"
  ];
}
