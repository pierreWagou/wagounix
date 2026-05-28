{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;
  authentikVersion = "2026.5.0";

  # Declarative branding blueprint — auto-applied by Authentik on startup
  brandBlueprint = pkgs.writeText "wagou-brand.yaml" ''
    version: 1
    metadata:
      name: Wagou - Custom Brand
      labels:
        blueprints.goauthentik.io/instantiate: "true"
    entries:
      - model: authentik_blueprints.metaapplyblueprint
        attrs:
          identifiers:
            name: Default - Authentication flow
          required: false

      - model: authentik_brands.brand
        state: present
        identifiers:
          domain: authentik-default
        attrs:
          default: true
          branding_title: Wagou
          branding_default_flow_background: https://dash.${host.domain}/bg/city.jpg
          branding_custom_css: |
            /* Catppuccin for Authentik — Light: Latte, Dark: Mocha, Accent: Mauve */
            :root {
              --ak-accent: #8839ef;
              --pf-global--primary-color--100: #8839ef;
              --pf-global--link--Color: #8839ef;
              --pf-global--link--Color--hover: #7287fd;
              --pf-global--BackgroundColor--100: #eff1f5;
              --pf-global--BackgroundColor--200: #e6e9ef;
              --pf-global--Color--100: #4c4f69;
              --pf-global--Color--200: #6c6f85;
              --pf-global--BorderColor--100: #ccd0da;
            }
            html[data-theme=dark] {
              --ak-accent: #cba6f7;
              --ak-dark-background: #1e1e2e;
              --ak-dark-background-light: #181825;
              --ak-dark-background-lighter: #313244;
              --ak-dark-foreground: #cdd6f4;
              --pf-global--primary-color--100: #cba6f7;
              --pf-global--link--Color: #cba6f7;
              --pf-global--link--Color--hover: #b4befe;
              --pf-global--BackgroundColor--100: #1e1e2e;
              --pf-global--BackgroundColor--200: #181825;
              --pf-global--BackgroundColor--dark-100: #1e1e2e;
              --pf-global--BackgroundColor--dark-200: #181825;
              --pf-global--BackgroundColor--dark-300: #313244;
              --pf-global--Color--100: #cdd6f4;
              --pf-global--Color--200: #a6adc8;
              --pf-global--BorderColor--100: #45475a;
            }
            .pf-c-login__main {
              background-color: rgba(49, 50, 68, 0.85) !important;
              border: 1px solid #45475a !important;
              border-radius: 8px !important;
              backdrop-filter: blur(10px) !important;
            }
            @media (prefers-color-scheme: light) {
              .pf-c-login__main {
                background-color: rgba(239, 241, 245, 0.85) !important;
                border: 1px solid #ccd0da !important;
              }
            }
            .pf-c-button.pf-m-primary {
              background-color: var(--ak-accent) !important;
              border-color: var(--ak-accent) !important;
            }
            .pf-c-button.pf-m-primary:hover {
              opacity: 0.85 !important;
            }
            ::-webkit-scrollbar { width: 8px; }
            ::-webkit-scrollbar-track { background: #181825; }
            ::-webkit-scrollbar-thumb { background: #45475a; border-radius: 4px; }
          flow_authentication: !Find [authentik_flows.flow, [slug, default-authentication-flow]]
          flow_invalidation: !Find [authentik_flows.flow, [slug, default-invalidation-flow]]
          flow_user_settings: !Find [authentik_flows.flow, [slug, default-user-settings-flow]]
  '';
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
          "${brandBlueprint}:/blueprints/custom/wagou-brand.yaml:ro"
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
          "${brandBlueprint}:/blueprints/custom/wagou-brand.yaml:ro"
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
