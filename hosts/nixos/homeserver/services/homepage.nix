{ config, host, ... }:

let
  # Place your photos in this directory (jpg, jpeg, png supported).
  # They are served by Caddy at /bg/* — no homepage-dashboard rebuild needed.
  imagesSrc = ./homepage-images;
  imageFiles = builtins.filter (f: builtins.match ".*\\.(jpg|jpeg|png)" f != null) (
    builtins.attrNames (builtins.readDir imagesSrc)
  );
  imageListJS = builtins.concatStringsSep ", " (map (f: ''"${f}"'') imageFiles);
in
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    openFirewall = false;
    allowedHosts = "${host.domain},home.${host.domain}";

    environmentFiles = [
      config.sops.templates."homepage.env".path
    ];

    settings = {
      title = "wagou://home";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      statusStyle = "dot";
      iconStyle = "theme";
      hideVersion = true;
      cardBlur = "sm";
      background = {
        image = "http://home.${host.domain}/bg/${builtins.head imageFiles}";
        blur = "sm";
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
          columns = 2;
        };
      };
    };

    customJS = ''
      // Randomly pick a background image on each page load.
      // Images are served by Caddy from hosts/nixos/homeserver/services/homepage-images/
      const images = [${imageListJS}];
      const pick = images[Math.floor(Math.random() * images.length)];
      const bgEl = document.getElementById("background");
      if (bgEl) {
        bgEl.style.backgroundImage = "url('/bg/" + pick + "')";
      }
    '';

    customCSS = ''
      :root {
        --card-bg:     rgba(15, 15, 20, 0.6);
        --card-border: rgba(255, 255, 255, 0.08);
        --card-hover:  rgba(255, 255, 255, 0.04);
        --text:        #e4e4e7;
        --text-muted:  #a1a1aa;
        --accent:      #a78bfa;
        --accent-soft: rgba(167, 139, 250, 0.15);
      }

      body {
        background: #0a0a0c !important;
      }

      .service-card {
        background: var(--card-bg) !important;
        border: 1px solid var(--card-border) !important;
        border-radius: 12px !important;
        backdrop-filter: blur(16px) saturate(120%);
        -webkit-backdrop-filter: blur(16px) saturate(120%);
        transition: all 0.2s ease !important;
      }

      .service-card:hover {
        background: var(--card-hover) !important;
        border-color: rgba(255, 255, 255, 0.15) !important;
        transform: translateY(-1px);
      }

      .service-name, .service-title {
        color: var(--text) !important;
        font-weight: 500 !important;
        font-size: 14px !important;
      }

      .service-description {
        color: var(--text-muted) !important;
        font-size: 12px !important;
      }

      .service-block, .bg-theme-200\/50 {
        background: var(--accent-soft) !important;
        border: 1px solid rgba(255, 255, 255, 0.06) !important;
        border-radius: 8px !important;
      }

      .service-block .uppercase {
        color: var(--accent) !important;
      }

      .service-block .font-thin {
        color: var(--text) !important;
      }

      .service-group-name {
        color: var(--text) !important;
        font-weight: 600 !important;
        text-transform: uppercase;
        letter-spacing: 1.5px;
        font-size: 12px !important;
      }

      #information-widgets {
        border-color: var(--card-border) !important;
      }

      #information-widgets * {
        color: var(--text-muted) !important;
      }

      .resource-usage {
        background: rgba(255, 255, 255, 0.06) !important;
        border-radius: 4px;
      }

      .resource-usage > div {
        background: var(--accent) !important;
      }

      .information-widget-greeting span {
        color: var(--text) !important;
      }

      .ping-up, [class*="bg-emerald"] {
        background-color: #34d399 !important;
      }

      .ping-down, [class*="bg-rose"] {
        background-color: #fb7185 !important;
      }

      ::-webkit-scrollbar { width: 6px; }
      ::-webkit-scrollbar-track { background: transparent; }
      ::-webkit-scrollbar-thumb {
        background: rgba(255, 255, 255, 0.15);
        border-radius: 3px;
      }
      ::-webkit-scrollbar-thumb:hover {
        background: rgba(255, 255, 255, 0.25);
      }

      #footer svg {
        color: var(--text-muted) !important;
      }
    '';

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
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
    ];

    services = [
      {
        "Services" = [
          {
            "Vaultwarden" = {
              icon = "vaultwarden.svg";
              href = "https://vault.${host.domain}";
              description = "Password manager";
              siteMonitor = "http://localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}";
            };
          }
          {
            "OpenCloud" = {
              icon = "owncloud.svg";
              href = "https://cloud.${host.domain}";
              description = "File sync & sharing";
              siteMonitor = "http://localhost:${toString config.services.opencloud.port}";
            };
          }
          {
            "Immich" = {
              icon = "immich.svg";
              href = "https://pixel.${host.domain}";
              description = "Photo management";
              siteMonitor = "http://localhost:${toString config.services.immich.port}";
              widget = {
                type = "immich";
                url = "http://localhost:${toString config.services.immich.port}";
                key = "{{HOMEPAGE_VAR_IMMICH_API_KEY}}";
                version = 2;
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
              href = "http://${host.serverIP}:3000";
              description = "DNS & ad blocking";
              siteMonitor = "http://localhost:3000";
            };
          }
          {
            "Cloudflare Tunnel" = {
              icon = "cloudflare.svg";
              description = "Secure remote access";
            };
          }
        ];
      }
    ];
  };
}
