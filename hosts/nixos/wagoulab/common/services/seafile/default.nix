{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;
  inherit (config.wagou) branding;
  ws = import ../lib/web-service.nix { inherit config host; };
  l = branding.palette.latte;
  m = branding.palette.mocha;

  # CSS variable blocks for light (Latte) and dark (Mocha) modes, prepended to the static CSS file
  seafileCssVars = ''
    /* === LIGHT MODE: Catppuccin Latte === */
    :root,
    [data-bs-theme=light] {
      --ctp-base: ${l.base}; --ctp-mantle: ${l.mantle}; --ctp-crust: ${l.crust};
      --ctp-surface0: ${l.surface0}; --ctp-surface1: ${l.surface1}; --ctp-surface2: ${l.surface2};
      --ctp-overlay0: ${l.overlay0}; --ctp-overlay1: ${l.overlay1};
      --ctp-text: ${l.text}; --ctp-subtext0: ${l.subtext0}; --ctp-subtext1: ${l.subtext1};
      --ctp-mauve: ${l.mauve}; --ctp-lavender: ${l.lavender};
      --ctp-red: ${l.red}; --ctp-green: ${l.green}; --ctp-yellow: ${l.yellow};
      --ctp-peach: ${l.peach}; --ctp-blue: ${l.blue};
      --bs-primary: ${l.mauve}; --bs-primary-rgb: 136, 57, 239;
    }

    /* === DARK MODE: Catppuccin Mocha === */
    [data-bs-theme=dark] {
      --ctp-base: ${m.base}; --ctp-mantle: ${m.mantle}; --ctp-crust: ${m.crust};
      --ctp-surface0: ${m.surface0}; --ctp-surface1: ${m.surface1}; --ctp-surface2: ${m.surface2};
      --ctp-overlay0: ${m.overlay0}; --ctp-overlay1: ${m.overlay1};
      --ctp-text: ${m.text}; --ctp-subtext0: ${m.subtext0}; --ctp-subtext1: ${m.subtext1};
      --ctp-mauve: ${m.mauve}; --ctp-lavender: ${m.lavender};
      --ctp-red: ${m.red}; --ctp-green: ${m.green}; --ctp-yellow: ${m.yellow};
      --ctp-peach: ${m.peach}; --ctp-blue: ${m.blue};
      --bs-primary: ${m.mauve}; --bs-primary-rgb: 203, 166, 247;
      color-scheme: dark;
    }
  '';

  customCss = pkgs.concatText "seafile-custom.css" [
    (pkgs.writeText "seafile-vars.css" seafileCssVars)
    ./seafile.css
  ];
  frontend = ws.mkWebService {
    name = "seafile";
    subdomain = "disk";
    image = "docker.io/seafileltd/seafile-mc:13.0.21";
    port = 80;
    env = {
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
      INIT_SEAFILE_ADMIN_EMAIL = host.adminEmail;
    };
    volumes = [
      "/var/lib/seafile:/shared"
    ];
    environmentFiles = [ config.sops.templates."seafile.env".path ];
    extraNetworks = [ networks.seafile-internal.ref ];
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
in
{
  # Seafile-internal network for DB, Redis, and SeaDoc (not exposed to Traefik)
  virtualisation.quadlet.networks.seafile-internal = { };

  # Complete seahub_settings.py rendered by sops-nix.
  # Applied automatically by ExecStartPre below (no manual step).
  sops.templates."seahub_settings.py" = {
    content = builtins.concatStringsSep "\n" [
      "SECRET_KEY = '${config.sops.placeholder.seafile-secret-key}'"
      "SERVICE_URL = 'https://disk.${host.domain}'"
      "FILE_SERVER_ROOT = 'https://disk.${host.domain}/seafhttp'"
      "TIME_ZONE = '${host.timezone}'"
      ""
      "CSRF_TRUSTED_ORIGINS = ['https://disk.${host.domain}']"
      ""
      "# Branding (media-relative: Seahub prepends /media/ to these paths)"
      "SITE_NAME = 'Wagou Disk'"
      "SITE_TITLE = 'Wagou Disk'"
      "LOGO_PATH = 'custom/logo-disk.svg'"
      "LOGO_WIDTH = 250"
      "LOGO_HEIGHT = 40"
      "FAVICON_PATH = 'custom/favicon.svg'"
      "LOGIN_BG_IMAGE_PATH = 'custom/city.jpg'"
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
      "OAUTH_PROVIDER_DOMAIN = 'https://auth.${host.domain}'"
      "OAUTH_AUTHORIZATION_URL = 'https://auth.${host.domain}/application/o/authorize/'"
      "OAUTH_TOKEN_URL = 'https://auth.${host.domain}/application/o/token/'"
      "OAUTH_USER_INFO_URL = 'https://auth.${host.domain}/application/o/userinfo/'"
      "OAUTH_SCOPE = ['openid', 'profile', 'email']"
      "OAUTH_ATTRIBUTE_MAP = {"
      "    'email': (True, 'email'),"
      "    'name': (False, 'name'),"
      "    'sub': (True, 'uid'),"
      "}"
      ""
      "# Disable local password login (OAuth-only)"
      "DISABLE_ADFS_USER_PWD_LOGIN = True"
      ""
      "# SSO via system browser for desktop/mobile clients"
      "CLIENT_SSO_VIA_LOCAL_BROWSER = True"
      ""
      "# SeaDoc"
      "ENABLE_SEADOC = True"
      ""
      "# OnlyOffice Docs (https://docs.${host.domain})"
      "ENABLE_ONLYOFFICE = True"
      "ONLYOFFICE_APIJS_URL = 'https://docs.${host.domain}/web-apps/apps/api/documents/api.js'"
      "ONLYOFFICE_JWT_SECRET = '${config.sops.placeholder.onlyoffice-jwt-secret}'"
      "ONLYOFFICE_FORCE_SAVE = True"
      "ONLYOFFICE_DESKTOP_EDITORS_PORTAL_LOGIN = True"
      "ONLYOFFICE_FILE_EXTENSION = ('doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'odt', 'odp', 'ods', 'csv')"
    ];
  };

  virtualisation.quadlet.containers = {
    seafile.containerConfig = frontend.containerConfig;
    seafile.unitConfig = frontend.unitConfig;

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
        image = host.valkeyImage;
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
        image = "docker.io/seafileltd/sdoc-server:2.0.8";
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

  # Seed declarative config + branding assets into the stateful volume before
  # every start. Seafile only reads these files from inside its self-initialized
  # data dir, so plain :ro mounts can't work (the paths don't exist until first
  # init). LOGO_PATH etc. are media-relative (Seahub prepends /media/), so the
  # asset files must live in seahub-data/custom/ — absolute imgproxy URLs get
  # mangled into /media/https://... and 404.
  # The guard preserves first-init: if conf/ is missing, Seafile hasn't
  # initialized yet — skip seeding and let it run. Never mkdir the conf dir
  # ourselves: its absence is the first-init signal.
  systemd.services.seafile.serviceConfig.ExecStartPre = [
    (pkgs.writeShellScript "seafile-seed" ''
      set -euo pipefail
      CONF_DIR="/var/lib/seafile/seafile/conf"
      CUSTOM_DIR="/var/lib/seafile/seafile/seahub-data/custom"
      if [ ! -d "$CONF_DIR" ]; then
        echo "seafile-seed: conf dir missing, skipping (first init not done)"
        exit 0
      fi
      cp ${config.sops.templates."seahub_settings.py".path} "$CONF_DIR/seahub_settings.py"
      chmod 644 "$CONF_DIR/seahub_settings.py"
      mkdir -p "$CUSTOM_DIR"
      cp ${customCss} "$CUSTOM_DIR/custom.css"
      cp ${branding.files.logoDisk} "$CUSTOM_DIR/logo-disk.svg"
      cp ${branding.files.favicon} "$CUSTOM_DIR/favicon.svg"
      cp ${branding.files.bgCity} "$CUSTOM_DIR/city.jpg"
      chmod 644 "$CUSTOM_DIR"/*
    '')
  ];
}
