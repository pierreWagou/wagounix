{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;
  inherit (config.wagou) branding;
  ws = import ../lib/web-service.nix { inherit config host; };
  authentikVersion = "2026.5.8";
  l = branding.palette.latte;
  m = branding.palette.mocha;

  # CSS variable blocks generated from palettes — injected before the static CSS file.
  # branding.css.ctpVars : shared :root { --ctp-* } block (Mocha, for always-dark elements)
  # cssVars              : :root light mode (Latte AK/PF tokens) + [theme=dark] (Mocha AK/PF tokens)
  cssVars = ''
    /* === Light mode (Latte) === */
    :host,
    :root {
      --ak-accent: ${l.mauve};
      --ak-accent-hover: ${l.lavender};
      --ak-on-accent: ${l.crust};
      --ak-surface-raised: ${l.surface0};
      --ak-surface-border: ${l.surface1};
      --ak-tooltip-bg: ${l.surface0};
      --ak-tooltip-text: ${l.text};
      --ak-sidebar-bg: ${l.mantle};
      --ak-sidebar-border: ${l.surface0};
      --ak-sidebar-text: ${l.subtext1};
      --ak-sidebar-text-hover: ${l.text};
      --ak-sidebar-text-active: ${l.mauve};
      --ak-sidebar-section-text: ${l.subtext0};
      --ak-sidebar-bg-hover: ${l.crust};
      --ak-sidebar-bg-active: ${l.surface0};
      --ak-input-bg: ${l.mantle};
      --ak-input-text: ${l.text};
      --ak-input-placeholder: ${l.overlay0};
      --ak-input-border: ${l.surface1};
      --ak-input-readonly-bg: ${l.crust};
      --pf-global--primary-color--100: var(--ak-accent);
      --pf-global--primary-color--dark-100: var(--ak-accent);
      --pf-global--link--Color: var(--ak-accent);
      --pf-global--link--Color--hover: var(--ak-accent-hover);
      --pf-global--link--Color--dark: var(--ak-accent);
      --pf-global--link--Color--dark--hover: var(--ak-accent-hover);
      --pf-global--BackgroundColor--100: ${l.base};
      --pf-global--BackgroundColor--200: ${l.mantle};
      --pf-global--Color--100: ${l.text};
      --pf-global--Color--200: ${l.subtext0};
      --pf-global--BorderColor--100: ${l.surface0};
      --pf-global--active-color--100: var(--ak-accent);
    }

    /* === Dark mode (Mocha) === */
    :host([theme="dark"]),
    html[data-theme=dark] {
      --ak-accent: ${m.mauve};
      --ak-accent-hover: ${m.lavender};
      --ak-on-accent: ${m.crust};
      --ak-surface-raised: ${m.surface0};
      --ak-surface-border: ${m.surface1};
      --ak-tooltip-bg: ${m.surface0};
      --ak-tooltip-text: ${m.text};
      --ak-sidebar-bg: ${m.mantle};
      --ak-sidebar-border: ${m.surface0};
      --ak-sidebar-text: ${m.subtext0};
      --ak-sidebar-text-hover: ${m.text};
      --ak-sidebar-text-active: ${m.lavender};
      --ak-sidebar-section-text: ${m.subtext1};
      --ak-sidebar-bg-hover: ${m.surface0};
      --ak-sidebar-bg-active: ${m.surface1};
      --ak-input-bg: ${m.mantle};
      --ak-input-text: ${m.text};
      --ak-input-placeholder: ${m.overlay0};
      --ak-input-border: ${m.surface1};
      --ak-input-readonly-bg: ${m.crust};
      --ak-dark-background: ${m.base};
      --ak-dark-background-light: ${m.mantle};
      --ak-dark-background-lighter: ${m.surface0};
      --ak-dark-foreground: ${m.text};
      --pf-global--primary-color--100: var(--ak-accent);
      --pf-global--primary-color--light-100: var(--ak-accent);
      --pf-global--link--Color: var(--ak-accent);
      --pf-global--link--Color--hover: var(--ak-accent-hover);
      --pf-global--link--Color--light: var(--ak-accent);
      --pf-global--BackgroundColor--100: ${m.base};
      --pf-global--BackgroundColor--200: ${m.mantle};
      --pf-global--BackgroundColor--dark-100: ${m.base};
      --pf-global--BackgroundColor--dark-200: ${m.mantle};
      --pf-global--BackgroundColor--dark-300: ${m.surface0};
      --pf-global--BackgroundColor--light-100: ${m.surface0};
      --pf-global--BackgroundColor--light-300: ${m.surface1};
      --pf-global--Color--100: ${m.text};
      --pf-global--Color--200: ${m.subtext0};
      --pf-global--Color--light-100: ${m.crust};
      --pf-global--BorderColor--100: ${m.surface1};
      --pf-global--active-color--100: var(--ak-accent);
    }
  '';

  # Escape CSS for embedding in a YAML double-quoted string
  escapedCss = builtins.replaceStrings [ "\\" "\"" "\n" ] [ "\\\\" "\\\"" "\\n" ] (
    branding.css.ctpVars + cssVars + builtins.readFile ./authentik.css
  );

  # Declarative branding blueprint — auto-applied by Authentik on startup.
  # pkgs.replaceVars substitutes @placeholder@ markers and verifies no markers remain.
  brandBlueprint = pkgs.replaceVars ./wagou-brand.yaml {
    logoUrl = branding.urls.logoAuth;
    faviconUrl = branding.urls.favicon;
    bgUrl = branding.urls.bgCity;
    customCss = escapedCss;
  };
  server = ws.mkWebService {
    name = "authentik";
    subdomain = "auth";
    image = "ghcr.io/goauthentik/server:${authentikVersion}";
    port = 9000;
    env = {
      AUTHENTIK_REDIS__HOST = "authentik-redis";
      AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
      AUTHENTIK_POSTGRESQL__USER = "authentik";
      AUTHENTIK_POSTGRESQL__NAME = "authentik";
    };
    environmentFiles = [ config.sops.templates."authentik.env".path ];
    volumes = [
      "/var/lib/authentik/media:/media"
      "/var/lib/authentik/templates:/templates"
      "${brandBlueprint}:/blueprints/custom/wagou-brand.yaml:ro"
    ];
    extraNetworks = [ networks.authentik-internal.ref ];
    exec = [ "server" ];
  };
  pg = ws.mkPostgres {
    name = "authentik-postgres";
    image = "docker.io/library/postgres:16-alpine";
    db = "authentik";
    user = "authentik";
    passwordEnvFile = config.sops.templates."authentik-postgres.env".path;
    networks = [ networks.authentik-internal.ref ];
  };
  cache = ws.mkValkey {
    name = "authentik-redis";
    networks = [ networks.authentik-internal.ref ];
  };
in
{
  sops = {
    secrets = {
      authentik-secret-key = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };

      authentik-postgres-password = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };

      authentik-ldap-token = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "authentik.env" = {
        content = builtins.concatStringsSep "\n" [
          "AUTHENTIK_SECRET_KEY=${config.sops.placeholder.authentik-secret-key}"
          "AUTHENTIK_POSTGRESQL__PASSWORD=${config.sops.placeholder.authentik-postgres-password}"
        ];
      };

      "authentik-postgres.env" = {
        content = "POSTGRES_PASSWORD=${config.sops.placeholder.authentik-postgres-password}\n";
      };

      "authentik-ldap.env" = {
        content = "AUTHENTIK_TOKEN=${config.sops.placeholder.authentik-ldap-token}\n";
      };
    };
  };

  # Authentik-internal network for DB and Redis (not exposed to Traefik)
  virtualisation.quadlet.networks.authentik-internal = { };

  virtualisation.quadlet.containers = {
    authentik-server.containerConfig = server.containerConfig;

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
          "${brandBlueprint}:/blueprints/custom/wagou-brand.yaml:ro"
        ];
        exec = [ "worker" ];
      };
    };

    authentik-postgres.containerConfig = pg.containerConfig;

    authentik-redis.containerConfig = cache.containerConfig;

    authentik-ldap = {
      containerConfig = {
        image = "ghcr.io/goauthentik/ldap:latest";
        noNewPrivileges = true;
        networks = [
          networks.proxy.ref
          networks.authentik-internal.ref
        ];
        environments = {
          AUTHENTIK_HOST = "http://authentik-server:9000";
          AUTHENTIK_INSECURE = "true";
        };
        environmentFiles = [ config.sops.templates."authentik-ldap.env".path ];
        publishPorts = [
          "0.0.0.0:389:3389/tcp"
          "0.0.0.0:636:6636/tcp"
        ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/authentik 0755 root root -"
    "d /var/lib/authentik/media 0755 root root -"
    "d /var/lib/authentik/templates 0755 root root -"
  ]
  ++ pg.tmpfilesRules
  ++ cache.tmpfilesRules;
}
