{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;

  # --- Branding Assets ---

  # Catppuccin Mocha theme with Mauve accent
  customCss = pkgs.writeText "seafile-custom.css" ''
    /* Catppuccin Mocha — https://catppuccin.com
       Accent: Mauve (#cba6f7) */

    :root {
      --ctp-base: #1e1e2e;
      --ctp-mantle: #181825;
      --ctp-crust: #11111b;
      --ctp-surface0: #313244;
      --ctp-surface1: #45475a;
      --ctp-surface2: #585b70;
      --ctp-overlay0: #6c7086;
      --ctp-overlay1: #7f849c;
      --ctp-text: #cdd6f4;
      --ctp-subtext0: #a6adc8;
      --ctp-subtext1: #bac2de;
      --ctp-mauve: #cba6f7;
      --ctp-lavender: #b4befe;
      --ctp-red: #f38ba8;
      --ctp-green: #a6e3a1;
      --ctp-yellow: #f9e2af;
      --ctp-peach: #fab387;
      --ctp-blue: #89b4fa;
    }

    /* === Global === */
    body,
    #wrapper,
    .main-panel,
    .main-panel-center {
      background-color: var(--ctp-base) !important;
      color: var(--ctp-text) !important;
    }

    /* === Header / Top Bar === */
    .top-header,
    .main-panel-north,
    #header,
    .header {
      background-color: var(--ctp-mantle) !important;
      border-bottom: 1px solid var(--ctp-surface0) !important;
    }

    /* === Sidebar === */
    .side-panel,
    .side-nav,
    .side-nav-con,
    .left-panel {
      background-color: var(--ctp-mantle) !important;
      border-right: 1px solid var(--ctp-surface0) !important;
    }

    .side-nav .nav-item,
    .side-nav a,
    .side-panel a {
      color: var(--ctp-subtext0) !important;
    }

    .side-nav .nav-item:hover,
    .side-nav a:hover,
    .side-panel a:hover {
      color: var(--ctp-text) !important;
      background-color: var(--ctp-surface0) !important;
    }

    .side-nav .nav-item.active,
    .side-nav .nav-item.active a {
      color: var(--ctp-mauve) !important;
      background-color: var(--ctp-surface0) !important;
    }

    /* === Links === */
    a {
      color: var(--ctp-mauve) !important;
    }

    a:hover {
      color: var(--ctp-lavender) !important;
    }

    /* === Buttons === */
    .btn-primary,
    .btn-primary:focus {
      background-color: var(--ctp-mauve) !important;
      border-color: var(--ctp-mauve) !important;
      color: var(--ctp-crust) !important;
    }

    .btn-primary:hover {
      background-color: var(--ctp-lavender) !important;
      border-color: var(--ctp-lavender) !important;
      color: var(--ctp-crust) !important;
    }

    .btn-secondary,
    .btn-outline-primary {
      background-color: var(--ctp-surface0) !important;
      border-color: var(--ctp-surface1) !important;
      color: var(--ctp-text) !important;
    }

    .btn-secondary:hover,
    .btn-outline-primary:hover {
      background-color: var(--ctp-surface1) !important;
      border-color: var(--ctp-mauve) !important;
      color: var(--ctp-mauve) !important;
    }

    /* === Cards, Panels, Modals === */
    .card,
    .panel,
    .modal-content,
    .dropdown-menu,
    .popover {
      background-color: var(--ctp-surface0) !important;
      border-color: var(--ctp-surface1) !important;
      color: var(--ctp-text) !important;
    }

    .modal-header,
    .modal-footer {
      border-color: var(--ctp-surface1) !important;
    }

    .dropdown-item {
      color: var(--ctp-text) !important;
    }

    .dropdown-item:hover {
      background-color: var(--ctp-surface1) !important;
      color: var(--ctp-mauve) !important;
    }

    /* === File List / Tables === */
    .table,
    .dir-content-list,
    .table-thead,
    table thead {
      background-color: var(--ctp-base) !important;
      color: var(--ctp-text) !important;
    }

    .table th,
    .table td {
      border-color: var(--ctp-surface0) !important;
      color: var(--ctp-text) !important;
    }

    .table-hover tbody tr:hover,
    .dir-content-list .file-item:hover {
      background-color: var(--ctp-surface0) !important;
    }

    .file-item,
    .dir-item {
      border-bottom: 1px solid var(--ctp-surface0) !important;
    }

    /* === Inputs & Forms === */
    input,
    textarea,
    select,
    .form-control {
      background-color: var(--ctp-surface0) !important;
      border-color: var(--ctp-surface1) !important;
      color: var(--ctp-text) !important;
    }

    input:focus,
    textarea:focus,
    select:focus,
    .form-control:focus {
      background-color: var(--ctp-surface0) !important;
      border-color: var(--ctp-mauve) !important;
      box-shadow: 0 0 0 0.2rem rgba(203, 166, 247, 0.25) !important;
      color: var(--ctp-text) !important;
    }

    input::placeholder,
    textarea::placeholder {
      color: var(--ctp-overlay0) !important;
    }

    /* === Breadcrumbs & Path === */
    .path-container,
    .breadcrumb {
      background-color: transparent !important;
      color: var(--ctp-subtext0) !important;
    }

    .breadcrumb a {
      color: var(--ctp-mauve) !important;
    }

    /* === Toolbar === */
    .toolbar,
    .dir-tool-bar,
    .operation-toolbar {
      background-color: var(--ctp-base) !important;
      border-bottom: 1px solid var(--ctp-surface0) !important;
    }

    /* === Search === */
    .search-input,
    .search-container input {
      background-color: var(--ctp-surface0) !important;
      border-color: var(--ctp-surface1) !important;
      color: var(--ctp-text) !important;
    }

    /* === Notifications, Alerts === */
    .alert-success {
      background-color: rgba(166, 227, 161, 0.1) !important;
      border-color: var(--ctp-green) !important;
      color: var(--ctp-green) !important;
    }

    .alert-danger,
    .alert-error {
      background-color: rgba(243, 139, 168, 0.1) !important;
      border-color: var(--ctp-red) !important;
      color: var(--ctp-red) !important;
    }

    .alert-warning {
      background-color: rgba(249, 226, 175, 0.1) !important;
      border-color: var(--ctp-yellow) !important;
      color: var(--ctp-yellow) !important;
    }

    /* === Scrollbars === */
    ::-webkit-scrollbar {
      width: 8px;
      height: 8px;
    }

    ::-webkit-scrollbar-track {
      background: var(--ctp-mantle);
    }

    ::-webkit-scrollbar-thumb {
      background: var(--ctp-surface1);
      border-radius: 4px;
    }

    ::-webkit-scrollbar-thumb:hover {
      background: var(--ctp-surface2);
    }

    /* === Login Page === */
    .login-panel,
    #login-form {
      background-color: rgba(30, 30, 46, 0.9) !important;
      border: 1px solid var(--ctp-surface1) !important;
      border-radius: 8px !important;
      backdrop-filter: blur(10px) !important;
    }

    .login-panel h1,
    .login-panel h2,
    .login-panel .login-title {
      color: var(--ctp-text) !important;
    }

    .login-panel .login-btn,
    .login-panel .submit-btn {
      background-color: var(--ctp-mauve) !important;
      border-color: var(--ctp-mauve) !important;
      color: var(--ctp-crust) !important;
    }

    .login-panel .login-btn:hover,
    .login-panel .submit-btn:hover {
      background-color: var(--ctp-lavender) !important;
      border-color: var(--ctp-lavender) !important;
    }

    /* === Tabs === */
    .nav-tabs .nav-link {
      color: var(--ctp-subtext0) !important;
    }

    .nav-tabs .nav-link.active {
      color: var(--ctp-mauve) !important;
      border-bottom-color: var(--ctp-mauve) !important;
      background-color: transparent !important;
    }

    .nav-tabs {
      border-bottom-color: var(--ctp-surface0) !important;
    }

    /* === Tooltip === */
    .tooltip-inner {
      background-color: var(--ctp-surface0) !important;
      color: var(--ctp-text) !important;
    }

    /* === Misc text overrides === */
    h1, h2, h3, h4, h5, h6,
    .heading,
    p,
    span,
    label,
    .text-muted {
      color: var(--ctp-text) !important;
    }

    .text-muted {
      color: var(--ctp-subtext0) !important;
    }

    /* === Icons === */
    .sf-icon,
    .op-icon,
    svg.icon {
      color: var(--ctp-subtext0) !important;
    }

    .sf-icon:hover,
    .op-icon:hover {
      color: var(--ctp-mauve) !important;
    }

    /* === Selection / Highlight === */
    ::selection {
      background-color: rgba(203, 166, 247, 0.3);
      color: var(--ctp-text);
    }

    /* === Loading spinner === */
    .loading-icon,
    .spinner-border {
      color: var(--ctp-mauve) !important;
    }

    /* === Footer === */
    footer,
    .main-panel-south {
      background-color: var(--ctp-mantle) !important;
      border-top: 1px solid var(--ctp-surface0) !important;
      color: var(--ctp-subtext0) !important;
    }
  '';

  # SVG logo: "WAGOU DISK" with neon Mauve glow
  logoSvg = pkgs.writeText "seafile-logo.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 40" width="220" height="40">
      <defs>
        <filter id="neon-glow" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="1.5" result="blur"/>
          <feColorMatrix in="blur" type="matrix"
            values="0 0 0 0 0.796
                    0 0 0 0 0.651
                    0 0 0 0 0.969
                    0 0 0 0.6 0" result="glow"/>
          <feMerge>
            <feMergeNode in="glow"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>
      <text x="10" y="28"
            font-family="'JetBrains Mono', 'Fira Code', 'SF Mono', monospace"
            font-size="20"
            font-weight="700"
            letter-spacing="2"
            fill="#cba6f7"
            filter="url(#neon-glow)">WAGOU DISK</text>
    </svg>
  '';

  # Favicon: compact "WD" icon with Catppuccin styling
  faviconSvg = pkgs.writeText "seafile-favicon.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
      <rect width="32" height="32" rx="6" fill="#1e1e2e"/>
      <rect x="1" y="1" width="30" height="30" rx="5" fill="none" stroke="#cba6f7" stroke-width="1.5" opacity="0.5"/>
      <text x="16" y="22"
            font-family="'JetBrains Mono', monospace"
            font-size="13"
            font-weight="700"
            fill="#cba6f7"
            text-anchor="middle">WD</text>
    </svg>
  '';

  # Login background — reuse homepage ocean image
  loginBg = ./homepage-images/ocean.jpg;
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
      "LOGO_WIDTH = 220"
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
    # Branding assets
    "d /var/lib/seafile/seafile/seahub-data/custom 0755 root root -"
    "C+ /var/lib/seafile/seafile/seahub-data/custom/custom.css 0644 root root - ${customCss}"
    "C+ /var/lib/seafile/seafile/seahub-data/custom/logo.svg 0644 root root - ${logoSvg}"
    "C+ /var/lib/seafile/seafile/seahub-data/custom/favicon.svg 0644 root root - ${faviconSvg}"
    "C+ /var/lib/seafile/seafile/seahub-data/custom/login-bg.jpg 0644 root root - ${loginBg}"
  ];

  # Idempotent script to deploy the complete seahub config
  # Run: sudo seafile-deploy
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "seafile-deploy" ''
      SETTINGS="/var/lib/seafile/seafile/conf/seahub_settings.py"
      if [ ! -d "/var/lib/seafile/seafile/conf" ]; then
        echo "Error: Seafile conf directory not found. Has Seafile been initialized?"
        exit 1
      fi
      cp ${config.sops.templates."seahub_settings.py".path} "$SETTINGS"
      chmod 644 "$SETTINGS"
      podman exec seafile /opt/seafile/seafile-server-latest/seahub.sh restart || \
        podman exec seafile /opt/seafile/seafile-server-latest/seahub.sh start
      echo "Done. Seahub config deployed."
    '')
  ];
}
