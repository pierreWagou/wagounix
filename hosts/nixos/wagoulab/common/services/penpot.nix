{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
  flags = "disable-registration enable-prepl-server disable-secure-session-cookies enable-mcp enable-admin-console";
  publicUri = "https://pantone.${host.domain}";
  penpotEnv = config.sops.templates."penpot.env".path;
in
{
  virtualisation.quadlet.containers = {
    penpot-frontend = {
      containerConfig = {
        image = "docker.io/penpotapp/frontend:2.18";
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ];
        volumes = [ "/var/lib/penpot/assets:/opt/data/assets" ];
        environments = {
          PENPOT_FLAGS = flags;
          PENPOT_HTTP_SERVER_MAX_BODY_SIZE = "367001600";
          PENPOT_PUBLIC_URI = publicUri;
          PENPOT_ADMIN_CONSOLE_URI = "http://penpot-admin-console:3000";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.penpot.rule" = "Host(`pantone.${host.domain}`)";
          "traefik.http.routers.penpot.entrypoints" = "websecure";
          "traefik.http.routers.penpot.tls" = "true";
          "traefik.http.routers.penpot.middlewares" = "secure-headers@file";
          "traefik.http.services.penpot.loadbalancer.server.port" = "8080";
        };
      };
      unitConfig = {
        After = [ "network-online.target" ];
      };
      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 300;
      };
    };

    penpot-backend = {
      containerConfig = {
        image = "docker.io/penpotapp/backend:2.18";
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ];
        volumes = [ "/var/lib/penpot/assets:/opt/data/assets" ];
        environments = {
          PENPOT_FLAGS = flags;
          PENPOT_HTTP_SERVER_MAX_BODY_SIZE = "367001600";
          PENPOT_PUBLIC_URI = publicUri;
          PENPOT_ADMIN_CONSOLE_URI = "http://penpot-admin-console:3000";
          PENPOT_DATABASE_URI = "postgresql://penpot-postgres/penpot";
          PENPOT_DATABASE_USERNAME = "penpot";
          PENPOT_REDIS_URI = "redis://penpot-valkey/0";
          PENPOT_OBJECTS_STORAGE_BACKEND = "fs";
          PENPOT_OBJECTS_STORAGE_FS_DIRECTORY = "/opt/data/assets";
          PENPOT_TELEMETRY_ENABLED = "false";
        };
        environmentFiles = [ penpotEnv ];
      };
      unitConfig = {
        After = [
          "network-online.target"
          "penpot-postgres.service"
          "penpot-valkey.service"
        ];
        Requires = [
          "penpot-postgres.service"
          "penpot-valkey.service"
        ];
      };
      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 300;
      };
    };

    penpot-exporter = {
      containerConfig = {
        image = "docker.io/penpotapp/exporter:2.18";
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ];
        environments = {
          PENPOT_FLAGS = flags;
          PENPOT_PUBLIC_URI = publicUri;
          PENPOT_INTERNAL_URI = "http://penpot-frontend:8080";
          PENPOT_REDIS_URI = "redis://penpot-valkey/0";
        };
        environmentFiles = [ penpotEnv ];
      };
      unitConfig = {
        After = [
          "network-online.target"
          "penpot-postgres.service"
          "penpot-valkey.service"
        ];
        Requires = [
          "penpot-postgres.service"
          "penpot-valkey.service"
        ];
      };
      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 300;
      };
    };

    penpot-admin-console = {
      containerConfig = {
        image = "docker.io/penpotapp/admin-console:2.18";
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ];
        environments = {
          PENPOT_PUBLIC_URI = publicUri;
          PENPOT_DATABASE_URI = "postgresql://penpot-postgres/penpot";
          PENPOT_DATABASE_USERNAME = "penpot";
          PENPOT_INTERNAL_URI = "http://penpot-frontend:8080";
        };
        environmentFiles = [ penpotEnv ];
      };
      unitConfig = {
        After = [
          "network-online.target"
          "penpot-postgres.service"
        ];
        Requires = [ "penpot-postgres.service" ];
      };
      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 300;
      };
    };

    penpot-mcp = {
      containerConfig = {
        image = "docker.io/penpotapp/mcp:2.18";
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ];
      };
      unitConfig = {
        After = [ "network-online.target" ];
      };
      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 300;
      };
    };

    penpot-postgres = {
      containerConfig = {
        image = "docker.io/library/postgres:15";
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ];
        volumes = [ "/var/lib/penpot/postgres:/var/lib/postgresql/data" ];
        environments = {
          POSTGRES_INITDB_ARGS = "--data-checksums";
          POSTGRES_DB = "penpot";
          POSTGRES_USER = "penpot";
        };
        environmentFiles = [ penpotEnv ];
      };
      unitConfig = {
        After = [ "network-online.target" ];
      };
      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 300;
      };
    };

    penpot-valkey = {
      containerConfig = {
        image = "docker.io/valkey/valkey:8.1";
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ];
        environments = {
          VALKEY_EXTRA_FLAGS = "--maxmemory 128mb --maxmemory-policy volatile-lfu";
        };
      };
      unitConfig = {
        After = [ "network-online.target" ];
      };
      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 300;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/penpot 0755 root root -"
    "d /var/lib/penpot/postgres 0755 root root -"
    "d /var/lib/penpot/assets 0755 root root -"
  ];
}
