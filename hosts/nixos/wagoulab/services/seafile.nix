{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;
in
{
  # Seafile-internal network for DB, Redis, and SeaDoc (not exposed to Traefik)
  virtualisation.quadlet.networks.seafile-internal = { };

  # OAuth config rendered by sops-nix
  # Deploy with: sudo seafile-deploy-oauth
  sops.templates."seafile-oauth.py" = {
    content = builtins.concatStringsSep "\n" [
      ""
      "# --- OAUTH START ---"
      "CSRF_TRUSTED_ORIGINS = ['https://disk.${host.domain}']"
      "ENABLE_OAUTH = True"
      "OAUTH_CREATE_UNKNOWN_USER = True"
      "OAUTH_ACTIVATE_USER_AFTER_CREATION = True"
      "OAUTH_CLIENT_ID = 'seafile'"
      "OAUTH_CLIENT_SECRET = '${config.sops.placeholder.seafile-oauth-client-secret}'"
      "OAUTH_REDIRECT_URL = 'https://disk.${host.domain}/oauth/callback/'"
      "OAUTH_PROVIDER_DOMAIN = 'https://cipher.${host.domain}'"
      "OAUTH_AUTHORIZATION_URL = 'https://cipher.${host.domain}/application/o/authorize/'"
      "OAUTH_TOKEN_URL = 'https://cipher.${host.domain}/application/o/token/'"
      "OAUTH_USER_INFO_URL = 'https://cipher.${host.domain}/application/o/userinfo/'"
      "OAUTH_SCOPE = ['openid', 'profile', 'email']"
      "OAUTH_ATTRIBUTE_MAP = {"
      "    'email': (True, 'email'),"
      "    'name': (False, 'name'),"
      "    'sub': (True, 'uid'),"
      "}"
      "CLIENT_SSO_VIA_LOCAL_BROWSER = True"
      "ENABLE_SEADOC = True"
      "# --- OAUTH END ---"
    ];
  };

  virtualisation.quadlet.containers = {
    seafile = {
      containerConfig = {
        image = "docker.io/seafileltd/seafile-mc:13.0-latest";
        noNewPrivileges = true;
        networks = [
          networks.proxy.ref
          networks.seafile-internal.ref
        ];
        volumes = [
          "/var/lib/seafile:/shared"
        ];
        environments = {
          SEAFILE_MYSQL_DB_HOST = "seafile-db";
          SEAFILE_MYSQL_DB_PORT = "3306";
          SEAFILE_MYSQL_DB_USER = "seafile";
          SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
          SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
          SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";
          TIME_ZONE = host.timezone;
          SEAFILE_SERVER_HOSTNAME = "disk.${host.domain}";
          SEAFILE_SERVER_PROTOCOL = "https";
          CACHE_PROVIDER = "redis";
          REDIS_HOST = "seafile-redis";
          REDIS_PORT = "6379";
          ENABLE_SEADOC = "true";
          INIT_SEAFILE_ADMIN_EMAIL = "pierre.romon@gmail.com";
          INIT_SEAFILE_ADMIN_PASSWORD = "changeme";
        };
        environmentFiles = [ config.sops.templates."seafile.env".path ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.seafile.rule" = "Host(`disk.${host.domain}`)";
          "traefik.http.routers.seafile.entrypoints" = "websecure";
          "traefik.http.routers.seafile.tls" = "true";
          "traefik.http.routers.seafile.middlewares" = "secure-headers@file";
          "traefik.http.services.seafile.loadbalancer.server.port" = "80";
        };
      };
      unitConfig = {
        Requires = [
          containers.seafile-db.ref
          containers.seafile-redis.ref
        ];
        After = [
          containers.seafile-db.ref
          containers.seafile-redis.ref
        ];
      };
    };

    seafile-db = {
      containerConfig = {
        image = "docker.io/library/mariadb:10.11";
        noNewPrivileges = true;
        networks = [ networks.seafile-internal.ref ];
        volumes = [ "/var/lib/seafile-mysql:/var/lib/mysql" ];
        environments = {
          MARIADB_AUTO_UPGRADE = "1";
          MYSQL_LOG_CONSOLE = "true";
        };
        environmentFiles = [ config.sops.templates."seafile-db.env".path ];
      };
    };

    seafile-redis = {
      containerConfig = {
        image = "docker.io/valkey/valkey:9.1.0";
        noNewPrivileges = true;
        networks = [ networks.seafile-internal.ref ];
        exec = [
          "--save"
          "60"
          "1"
          "--loglevel"
          "warning"
        ];
        volumes = [ "/var/lib/seafile-redis:/data" ];
      };
    };

    seadoc = {
      containerConfig = {
        image = "docker.io/seafileltd/sdoc-server:2.0-latest";
        noNewPrivileges = true;
        networks = [ networks.seafile-internal.ref ];
        volumes = [ "/var/lib/seadoc:/shared" ];
        environments = {
          SEAFILE_SERVER_HOSTNAME = "disk.${host.domain}";
          SEAFILE_SERVER_PROTOCOL = "https";
        };
        environmentFiles = [ config.sops.templates."seafile.env".path ];
      };
      unitConfig = {
        Requires = [ containers.seafile.ref ];
        After = [ containers.seafile.ref ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/seafile 0755 root root -"
    "d /var/lib/seafile-mysql 0755 root root -"
    "d /var/lib/seafile-redis 0755 root root -"
    "d /var/lib/seadoc 0755 root root -"
  ];

  # Idempotent script to deploy/update OAuth config into Seafile
  # Run: sudo seafile-deploy-oauth
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "seafile-deploy-oauth" ''
      SETTINGS="/var/lib/seafile/seafile/conf/seahub_settings.py"
      if [ ! -f "$SETTINGS" ]; then
        echo "Error: $SETTINGS not found. Is Seafile running?"
        exit 1
      fi
      # Remove old OAuth block if present
      if grep -q "# --- OAUTH START ---" "$SETTINGS"; then
        sed -i '/^# --- OAUTH START ---$/,/^# --- OAUTH END ---$/d' "$SETTINGS"
      fi
      # Append fresh OAuth config from sops
      cat /run/secrets/rendered/seafile-oauth.py >> "$SETTINGS"
      # Restart seahub to pick up the new config
      podman exec seafile /opt/seafile/seafile-server-latest/seahub.sh restart
      echo "Done. OAuth config deployed to Seafile."
    '')
  ];
}
