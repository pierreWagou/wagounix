{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;
  inherit (config.wagou) branding;

  # Branding assets from the shared module
  customCss = branding.css.seafile;
  logoSvg = branding.mkLogo "DISK";
  faviconSvg = branding.favicon;
  loginBg = branding.loginBackground;
in
{
  # Seafile-internal network for DB, Redis, and SeaDoc (not exposed to Traefik)
  virtualisation.quadlet.networks.seafile-internal = { };

  # Complete seahub_settings.py rendered by sops-nix
  # Deploy with: sudo seafile-deploy
  sops.templates."seahub_settings.py" = {
    content = builtins.concatStringsSep "\n" [
      "SECRET_KEY = '${config.sops.placeholder.seafile-secret-key}'"
      "SERVICE_URL = 'https://disk.${host.domain}'"
      "FILE_SERVER_ROOT = 'https://disk.${host.domain}/seafhttp'"
      "TIME_ZONE = '${host.timezone}'"
      ""
      "CSRF_TRUSTED_ORIGINS = ['https://disk.${host.domain}']"
      ""
      "# Branding"
      "SITE_NAME = 'Wagou Disk'"
      "SITE_TITLE = 'Wagou Disk'"
      "LOGO_PATH = 'custom/logo.svg'"
      "LOGO_WIDTH = 150"
      "LOGO_HEIGHT = 40"
      "FAVICON_PATH = 'custom/favicon.svg'"
      "LOGIN_BG_IMAGE_PATH = 'custom/login-bg.jpg'"
      "BRANDING_CSS = 'custom/custom.css'"
      "ENABLE_SETTINGS_VIA_WEB = False"
      ""
      "# OAuth/OIDC via Authentik"
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
      ""
      "# SSO via system browser for desktop/mobile clients"
      "CLIENT_SSO_VIA_LOCAL_BROWSER = True"
      ""
      "# SeaDoc"
      "ENABLE_SEADOC = True"
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
    "d /var/lib/seafile-redis 0750 999 999 -"
    "Z /var/lib/seafile-redis 0750 999 999 -"
    "d /var/lib/seadoc 0755 root root -"
    # Branding assets directory
    "d /var/lib/seafile/seafile/seahub-data/custom 0755 root root -"
  ];

  # Idempotent script to deploy seahub config + branding
  # Run: sudo seafile-deploy
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "seafile-deploy" ''
      SETTINGS="/var/lib/seafile/seafile/conf/seahub_settings.py"
      CUSTOM="/var/lib/seafile/seafile/seahub-data/custom"
      if [ ! -d "/var/lib/seafile/seafile/conf" ]; then
        echo "Error: Seafile conf directory not found. Has Seafile been initialized?"
        exit 1
      fi
      # Deploy seahub config
      cp ${config.sops.templates."seahub_settings.py".path} "$SETTINGS"
      chmod 644 "$SETTINGS"
      # Deploy branding assets
      mkdir -p "$CUSTOM"
      cp ${customCss} "$CUSTOM/custom.css"
      cp ${logoSvg} "$CUSTOM/logo.svg"
      cp ${faviconSvg} "$CUSTOM/favicon.svg"
      cp ${loginBg} "$CUSTOM/login-bg.jpg"
      chmod 644 "$CUSTOM"/*
      # Restart seahub
      podman exec seafile /opt/seafile/seafile-server-latest/seahub.sh restart || \
        podman exec seafile /opt/seafile/seafile-server-latest/seahub.sh start
      echo "Done. Seahub config + branding deployed."
    '')
  ];
}
