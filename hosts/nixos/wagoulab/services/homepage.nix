{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;

  # Background images — served by an nginx sidecar container at /bg/*
  homepageImages = ./homepage-images;
  imageFiles = builtins.filter (f: builtins.match ".*\\.(jpg|jpeg|png)" f != null) (
    builtins.attrNames (builtins.readDir homepageImages)
  );
  defaultImage = if imageFiles != [ ] then builtins.head imageFiles else "placeholder.jpg";
  imageListJS = builtins.concatStringsSep ", " (map (f: ''"${f}"'') imageFiles);

  yamlFormat = pkgs.formats.yaml { };

  settingsFile = yamlFormat.generate "settings.yaml" {
    title = "wagoulab://dash";
    favicon = "https://dash.${host.domain}/bg/favicon.svg";
    logo = "https://dash.${host.domain}/bg/favicon.svg";
    theme = "dark";
    color = "slate";
    headerStyle = "clean";
    statusStyle = "dot";
    iconStyle = "theme";
    hideVersion = true;
    cardBlur = "sm";
    background = {
      image = "https://dash.${host.domain}/bg/${defaultImage}";
      blur = "xl";
      brightness = 75;
      opacity = 75;
    };
    layout = {
      Services = {
        style = "row";
        columns = 3;
      };
      Media = {
        style = "row";
        columns = 2;
      };
      Infrastructure = {
        style = "row";
        columns = 2;
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
        latitude = 48.8566;
        longitude = 2.3522;
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
          "OpenCloud" = {
            icon = "owncloud.svg";
            href = "https://cloud.${host.domain}";
            description = "File sync & sharing";
            siteMonitor = "http://opencloud:9200";
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
      --ctp-base:      #1e1e2e;
      --ctp-mantle:    #181825;
      --ctp-crust:     #11111b;
      --ctp-surface0:  #313244;
      --ctp-surface1:  #45475a;
      --ctp-surface2:  #585b70;
      --ctp-overlay0:  #6c7086;
      --ctp-text:      #cdd6f4;
      --ctp-subtext0:  #a6adc8;
      --ctp-subtext1:  #bac2de;
      --ctp-lavender:  #b4befe;
      --ctp-mauve:     #cba6f7;
      --ctp-pink:      #f5c2e7;
      --ctp-green:     #a6e3a1;
      --ctp-red:       #f38ba8;
      --ctp-peach:     #fab387;
      --ctp-blue:      #89b4fa;
      --ctp-teal:      #94e2d5;
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
      bgEl.style.backgroundImage = "url('/bg/" + pick + "')";
    }
  '';

  # Nginx config to serve background images at /bg/*
  nginxConf = pkgs.writeText "nginx-homepage-images.conf" ''
    server {
      listen 8090;
      location /bg/ {
        alias /usr/share/nginx/html/bg/;
      }
    }
  '';
in
{
  virtualisation.quadlet.containers = {
    homepage = {
      containerConfig = {
        image = "ghcr.io/gethomepage/homepage:latest";
        healthCmd = "none";
        networks = [ networks.proxy.ref ];
        volumes = [
          "${settingsFile}:/app/config/settings.yaml:ro"
          "${widgetsFile}:/app/config/widgets.yaml:ro"
          "${servicesFile}:/app/config/services.yaml:ro"
          "${bookmarksFile}:/app/config/bookmarks.yaml:ro"
          "${customCSS}:/app/config/custom.css:ro"
          "${customJS}:/app/config/custom.js:ro"
          "/var/lib/wagoulab/homepage-logs:/app/config/logs"
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

    # Lightweight nginx sidecar to serve background images at /bg/*
    homepage-images = {
      containerConfig = {
        image = "docker.io/library/nginx:alpine";
        networks = [ networks.proxy.ref ];
        volumes = [
          "${homepageImages}:/usr/share/nginx/html/bg:ro"
          "${nginxConf}:/etc/nginx/conf.d/default.conf:ro"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.homepage-images.rule" = "Host(`dash.${host.domain}`) && PathPrefix(`/bg/`)";
          "traefik.http.routers.homepage-images.entrypoints" = "websecure";
          "traefik.http.routers.homepage-images.tls" = "true";
          "traefik.http.routers.homepage-images.priority" = "100";
          "traefik.http.services.homepage-images.loadbalancer.server.port" = "8090";
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/wagoulab/homepage-logs 0755 root root -"
  ];
}
