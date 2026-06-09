{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;
  inherit (config.wagou) branding;
  m = branding.palette.mocha;

  # Branding assets — image list for random background picker
  brandingAssetsDir = ./branding-assets;
  imageFiles = builtins.filter (f: builtins.match ".*\\.(jpg|jpeg|png)" f != null) (
    builtins.attrNames (builtins.readDir brandingAssetsDir)
  );
  imageListJS = builtins.concatStringsSep ", " (
    map (f: ''"${branding.baseUrl}/plain/local:///${f}"'') imageFiles
  );

  yamlFormat = pkgs.formats.yaml { };

  settingsFile = yamlFormat.generate "settings.yaml" {
    title = "wagoulab://dash";
    inherit (branding.urls) favicon;
    logo = branding.urls.favicon;
    theme = "dark";
    color = "slate";
    headerStyle = "clean";
    statusStyle = "dot";
    iconStyle = "theme";
    hideVersion = true;
    cardBlur = "sm";
    background = {
      image = branding.urls.bgCity;
      blur = "xl";
      brightness = 75;
      opacity = 75;
    };
    layout = {
      Services = {
        style = "row";
        columns = 4;
      };
      Media = {
        style = "row";
        columns = 2;
      };
      Infrastructure = {
        style = "row";
        columns = 3;
      };
    };
  };

  widgetsFile = yamlFormat.generate "widgets.yaml" [
    {
      greeting = {
        text_size = "xl";
        text = "There's no place like 127.0.0.1";
      };
    }
    {
      datetime = {
        text_size = "xl";
        format = {
          dateStyle = "long";
          timeStyle = "short";
        };
      };
    }
    {
      openmeteo = {
        label = "Paris";
        inherit (host) latitude longitude;
        units = "metric";
      };
    }
    {
      resources = {
        cpu = true;
        memory = true;
        disk = "/";
      };
    }
  ];

  servicesFile = yamlFormat.generate "services.yaml" [
    {
      "Services" = [
        {
          "Vaultwarden" = {
            icon = "vaultwarden.svg";
            href = "https://vault.${host.domain}";
            description = "Password manager";
            siteMonitor = "http://vaultwarden:80";
          };
        }
        {
          "Seafile" = {
            icon = "seafile.svg";
            href = "https://disk.${host.domain}";
            description = "File sync & sharing";
            siteMonitor = "http://seafile:80";
          };
        }
        {
          "Immich" = {
            icon = "immich.svg";
            href = "https://pixel.${host.domain}";
            description = "Photo management";
            siteMonitor = "http://immich-server:2283";
            widget = {
              type = "immich";
              url = "http://immich-server:2283";
              key = "{{HOMEPAGE_VAR_IMMICH_API_KEY}}";
              version = 2;
            };
          };
        }
        {
          "KitchenOwl" = {
            icon = "kitchenowl.svg";
            href = "https://cabas.${host.domain}";
            description = "Recipes & grocery lists";
            siteMonitor = "http://kitchenowl:8080";
          };
        }
        {
          "Creneau" = {
            icon = "calendar.svg";
            href = "https://creneau.${host.domain}";
            description = "Appointment scheduling";
            siteMonitor = "http://creneau:3000";
          };
        }
      ];
    }
    {
      "Media" = [
        {
          "Home Assistant" = {
            icon = "home-assistant.svg";
            href = "https://home.${host.domain}";
            description = "Home automation";
            siteMonitor = "http://home-assistant:8123";
          };
        }
        {
          "Jellyfin" = {
            icon = "jellyfin.svg";
            href = "https://tape.${host.domain}";
            description = "Media server";
            siteMonitor = "http://jellyfin:8096";
            widget = {
              type = "jellyfin";
              url = "http://jellyfin:8096";
              key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
              enableBlocks = true;
              enableNowPlaying = false;
            };
          };
        }
      ];
    }
    {
      "Infrastructure" = [
        {
          "Authentik" = {
            icon = "authentik.svg";
            href = "https://auth.${host.domain}";
            description = "Identity provider";
            siteMonitor = "http://authentik-server:9000";
          };
        }
        {
          "Traefik" = {
            icon = "traefik.svg";
            description = "Reverse proxy";
            widget = {
              type = "traefik";
              url = "http://traefik:8080";
            };
          };
        }
        {
          "AdGuard Home" = {
            icon = "adguard-home.svg";
            href = "https://guard.${host.domain}";
            description = "DNS & ad blocking";
            siteMonitor = "http://adguard:3000";
            widget = {
              type = "adguard";
              url = "http://adguard:3000";
              username = "{{HOMEPAGE_VAR_ADGUARD_USER}}";
              password = "{{HOMEPAGE_VAR_ADGUARD_PASS}}";
            };
          };
        }
        {
          "Cloudflare Tunnel" = {
            icon = "cloudflare.svg";
            description = "Secure remote access";
            widget = {
              type = "cloudflared";
              accountid = host.cloudflareAccountId;
              tunnelid = host.cloudflareTunnelId;
              key = "{{HOMEPAGE_VAR_CF_API_TOKEN}}";
            };
          };
        }
        {
          "ttyd" = {
            icon = "terminal.svg";
            href = "https://dev.${host.domain}";
            description = "Web terminal";
            siteMonitor = "http://127.0.0.1:${toString host.ports.ttyd}";
          };
        }
      ];
    }
  ];

  bookmarksFile = yamlFormat.generate "bookmarks.yaml" [ ];

  customCSS = pkgs.writeText "custom.css" ''
    :root {
      --color-theme-50:  205 214 244;
      --color-theme-100: 186 194 222;
      --color-theme-200: 166 173 200;
      --color-theme-300: 108 112 134;
      --color-theme-400: 88 91 112;
      --color-theme-500: 69 71 90;
      --color-theme-600: 49 50 68;
      --color-theme-700: 30 30 46;
      --color-theme-800: 24 24 37;
      --color-theme-900: 17 17 27;
      --bg-color: 17 17 27;
      --ctp-base:      ${m.base};
      --ctp-mantle:    ${m.mantle};
      --ctp-crust:     ${m.crust};
      --ctp-surface0:  ${m.surface0};
      --ctp-surface1:  ${m.surface1};
      --ctp-surface2:  ${m.surface2};
      --ctp-overlay0:  ${m.overlay0};
      --ctp-text:      ${m.text};
      --ctp-subtext0:  ${m.subtext0};
      --ctp-subtext1:  ${m.subtext1};
      --ctp-lavender:  ${m.lavender};
      --ctp-mauve:     ${m.mauve};
      --ctp-green:     ${m.green};
      --ctp-red:       ${m.red};
      --ctp-peach:     ${m.peach};
      --ctp-blue:      ${m.blue};
    }
    body { background: var(--ctp-crust) !important; }
    .service-card { background: rgba(30, 30, 46, 0.7) !important; border: 1px solid rgba(69, 71, 90, 0.5) !important; border-radius: 12px !important; backdrop-filter: blur(16px) saturate(120%); -webkit-backdrop-filter: blur(16px) saturate(120%); transition: all 0.2s ease !important; }
    .service-card:hover { background: rgba(49, 50, 68, 0.8) !important; border-color: var(--ctp-lavender) !important; transform: translateY(-1px); }
    .service-name, .service-title { color: var(--ctp-text) !important; font-weight: 500 !important; }
    .service-description { color: var(--ctp-subtext0) !important; }
    .service-block, .bg-theme-200\/50 { background: rgba(203, 166, 247, 0.1) !important; border: 1px solid rgba(69, 71, 90, 0.4) !important; border-radius: 8px !important; }
    .service-block .uppercase { color: var(--ctp-mauve) !important; }
    .service-block .font-thin { color: var(--ctp-text) !important; }
    .service-group-name { color: var(--ctp-mauve) !important; font-weight: 600 !important; text-transform: uppercase; letter-spacing: 1.5px; font-size: 12px !important; }
    #information-widgets { border-color: var(--ctp-surface0) !important; }
    .information-widget-resource:nth-child(1) .resource-icon { color: var(--ctp-blue) !important; }
    .information-widget-resource:nth-child(2) .resource-icon { color: var(--ctp-mauve) !important; }
    .information-widget-resource:nth-child(3) .resource-icon { color: var(--ctp-peach) !important; }
    .information-widget-resource .text-xs { color: var(--ctp-lavender) !important; }
    .resource-usage { background: var(--ctp-surface0) !important; border-radius: 4px; }
    .information-widget-resource:nth-child(1) .resource-usage > div { background: var(--ctp-blue) !important; }
    .information-widget-resource:nth-child(2) .resource-usage > div { background: var(--ctp-mauve) !important; }
    .information-widget-resource:nth-child(3) .resource-usage > div { background: var(--ctp-peach) !important; }
    .information-widget-datetime span { color: var(--ctp-lavender) !important; }
    .ping-up, [class*="bg-emerald"] { background-color: var(--ctp-green) !important; }
    .ping-down, [class*="bg-rose"] { background-color: var(--ctp-red) !important; }
    ::-webkit-scrollbar { width: 6px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: var(--ctp-surface1); border-radius: 3px; }
    ::-webkit-scrollbar-thumb:hover { background: var(--ctp-surface2); }
    .information-widget-greeting { order: 99; width: 100%; text-align: center; padding-top: 1rem; padding-bottom: 0.5rem; }
    .information-widget-greeting span { font-size: 1.4rem !important; font-weight: 600; color: var(--ctp-lavender) !important; letter-spacing: 0.5px; }
    #footer svg { color: var(--ctp-overlay0) !important; }
  '';

  customJS = pkgs.writeText "custom.js" ''
    const images = [${imageListJS}];
    const pick = images[Math.floor(Math.random() * images.length)];
    const bgEl = document.getElementById("background");
    if (bgEl) {
      bgEl.style.backgroundImage = "url('" + pick + "')";
    }
  '';
in
{
  virtualisation.quadlet.containers = {
    homepage = {
      containerConfig = {
        image = "ghcr.io/gethomepage/homepage:v1.13.1";
        noNewPrivileges = true;
        healthCmd = "none";
        networks = [ networks.proxy.ref ];
        volumes = [
          "${settingsFile}:/app/config/settings.yaml:ro"
          "${widgetsFile}:/app/config/widgets.yaml:ro"
          "${servicesFile}:/app/config/services.yaml:ro"
          "${bookmarksFile}:/app/config/bookmarks.yaml:ro"
          "${customCSS}:/app/config/custom.css:ro"
          "${customJS}:/app/config/custom.js:ro"
          "/var/lib/${host.hostname}/homepage-logs:/app/config/logs"
        ];
        environments = {
          HOMEPAGE_ALLOWED_HOSTS = "${host.domain},dash.${host.domain}";
        };
        environmentFiles = [ config.sops.templates."homepage.env".path ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.homepage.rule" = "Host(`dash.${host.domain}`)";
          "traefik.http.routers.homepage.entrypoints" = "websecure";
          "traefik.http.routers.homepage.tls" = "true";
          "traefik.http.routers.homepage.middlewares" = "secure-headers@file";
          "traefik.http.services.homepage.loadbalancer.server.port" = "3000";
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/${host.hostname}/homepage-logs 0755 root root -"
  ];
}
