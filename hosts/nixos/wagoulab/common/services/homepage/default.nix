{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.wagou) branding;
  ws = import ../lib/web-service.nix { inherit config host; };
  brandingAssetsDir = ../branding-assets;
  imageFiles = builtins.filter (f: builtins.match ".*\\.(jpg|jpeg|png)" f != null) (
    builtins.attrNames (builtins.readDir brandingAssetsDir)
  );
  imageListJS = builtins.concatStringsSep ", " (
    map (f: ''"${branding.baseUrl}/plain/local:///${f}"'') imageFiles
  );

  yamlFormat = pkgs.formats.yaml { };

  settingsFile = yamlFormat.generate "settings.yaml" {
    title = "wagou-prime://dash";
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
        columns = 3;
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
          "KitchenOwl" = {
            icon = "kitchenowl.svg";
            href = "https://cabas.${host.domain}";
            description = "Recipes & grocery lists";
            siteMonitor = "http://kitchenowl:8080";
          };
        }
        {
          "Stalwart Mail" = {
            icon = "stalwart-mail.svg";
            href = "https://mailbox.${host.domain}";
            description = "Email server";
            siteMonitor = "http://stalwart:8080";
          };
        }
        {
          "Dokploy" = {
            icon = "dokploy.svg";
            href = "https://apps.${host.domain}";
            description = "PaaS app deployment";
          };
        }
        {
          "Home Assistant" = {
            icon = "home-assistant.svg";
            href = "https://home.${host.domain}";
            description = "Home automation";
            siteMonitor = "http://home-assistant:8123";
          };
        }
        {
          "Satisfactory" = {
            icon = "mdi-gamepad-variant";
            description = "Game server";
          };
        }
      ];
    }
    {
      "Infrastructure" = [
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
          "Firecrawl" = {
            icon = "mdi-spider";
            href = "https://crawl.${host.domain}";
            description = "Web search & crawl API";
            siteMonitor = "http://firecrawl-api:3002";
          };
        }
        {
          "Authentik" = {
            icon = "authentik.svg";
            href = "https://auth.${host.domain}";
            description = "Identity provider";
            siteMonitor = "http://authentik-server:9000";
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
        {
          "Webhook" = {
            icon = "webhook.svg";
            href = "https://relay.${host.domain}";
            description = "GitHub webhook receiver";
            siteMonitor = "http://127.0.0.1:${toString host.ports.webhook}";
          };
        }
        {
          "Branding" = {
            icon = "palette.svg";
            href = "https://assets.${host.domain}";
            description = "Image proxy & assets";
            siteMonitor = "http://imgproxy:8080";
          };
        }
      ];
    }
  ];

  bookmarksFile = yamlFormat.generate "bookmarks.yaml" [ ];

  customCSS = pkgs.concatText "custom.css" [
    (pkgs.writeText "ctp-vars.css" branding.css.ctpVars)
    ./custom.css
  ];

  customJS = pkgs.writeText "custom.js" ''
    const images = [${imageListJS}];
    const pick = images[Math.floor(Math.random() * images.length)];
    const bgEl = document.getElementById("background");
    if (bgEl) {
      bgEl.style.backgroundImage = "url('" + pick + "')";
    }
  '';
  homepage = ws.mkWebService {
    name = "homepage";
    subdomain = "dash";
    image = "ghcr.io/gethomepage/homepage:v1.13.1";
    port = 3000;
    healthCmd = "none";
    env = {
      HOMEPAGE_ALLOWED_HOSTS = "${host.domain},dash.${host.domain}";
    };
    volumes = [
      "${settingsFile}:/app/config/settings.yaml:ro"
      "${widgetsFile}:/app/config/widgets.yaml:ro"
      "${servicesFile}:/app/config/services.yaml:ro"
      "${bookmarksFile}:/app/config/bookmarks.yaml:ro"
      "${customCSS}:/app/config/custom.css:ro"
      "${customJS}:/app/config/custom.js:ro"
      "/var/lib/${host.hostname}/homepage-logs:/app/config/logs"
    ];
    environmentFiles = [ config.sops.templates."homepage.env".path ];
    dataDirs = [ "/var/lib/${host.hostname}/homepage-logs" ];
  };
in
{
  sops = {
    secrets = {
      cloudflare-tunnel-token = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "homepage.env" = {
        content = builtins.concatStringsSep "\n" [
          "HOMEPAGE_VAR_IMMICH_API_KEY=${config.sops.placeholder.immich-api-key}"
          "HOMEPAGE_VAR_ADGUARD_USER=admin"
          "HOMEPAGE_VAR_ADGUARD_PASS=${config.sops.placeholder.adguard-password}"
          "HOMEPAGE_VAR_CF_API_TOKEN=${config.sops.placeholder.cloudflare-tunnel-token}"
          "HOMEPAGE_VAR_JELLYFIN_API_KEY=${config.sops.placeholder.jellyfin-api-key}"
        ];
      };
    };
  };

  virtualisation.quadlet.containers = {
    homepage.containerConfig = homepage.containerConfig;
  };

  systemd.tmpfiles.rules = homepage.tmpfilesRules;
}
