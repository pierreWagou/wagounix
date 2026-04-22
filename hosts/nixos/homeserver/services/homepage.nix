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

        --card-bg:       rgba(30, 30, 46, 0.7);
        --card-border:   rgba(69, 71, 90, 0.5);
        --card-hover:    rgba(49, 50, 68, 0.8);
      }

      body {
        background: var(--ctp-crust) !important;
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
        border-color: var(--ctp-lavender) !important;
        transform: translateY(-1px);
      }

      .service-name, .service-title {
        color: var(--ctp-text) !important;
        font-weight: 500 !important;
        font-size: 14px !important;
      }

      .service-description {
        color: var(--ctp-subtext0) !important;
        font-size: 12px !important;
      }

      .service-block, .bg-theme-200\/50 {
        background: rgba(203, 166, 247, 0.1) !important;
        border: 1px solid rgba(69, 71, 90, 0.4) !important;
        border-radius: 8px !important;
      }

      .service-block .uppercase {
        color: var(--ctp-mauve) !important;
      }

      .service-block .font-thin {
        color: var(--ctp-text) !important;
      }

      .service-group-name {
        color: var(--ctp-lavender) !important;
        font-weight: 600 !important;
        text-transform: uppercase;
        letter-spacing: 1.5px;
        font-size: 12px !important;
      }

      #information-widgets {
        border-color: var(--ctp-surface0) !important;
      }

      #information-widgets * {
        color: var(--ctp-subtext1) !important;
      }

      .resource-usage {
        background: var(--ctp-surface0) !important;
        border-radius: 4px;
      }

      .resource-usage > div {
        background: var(--ctp-mauve) !important;
      }

      .information-widget-greeting span {
        color: var(--ctp-text) !important;
      }

      .ping-up, [class*="bg-emerald"] {
        background-color: var(--ctp-green) !important;
      }

      .ping-down, [class*="bg-rose"] {
        background-color: var(--ctp-red) !important;
      }

      ::-webkit-scrollbar { width: 6px; }
      ::-webkit-scrollbar-track { background: transparent; }
      ::-webkit-scrollbar-thumb {
        background: var(--ctp-surface1);
        border-radius: 3px;
      }
      ::-webkit-scrollbar-thumb:hover {
        background: var(--ctp-surface2);
      }

      #footer svg {
        color: var(--ctp-overlay0) !important;
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
