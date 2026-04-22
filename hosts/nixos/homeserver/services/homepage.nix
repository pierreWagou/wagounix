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
      color = "fuchsia";
      headerStyle = "clean";
      statusStyle = "dot";
      iconStyle = "theme";
      hideVersion = true;
      cardBlur = "sm";
      background = {
        image = "http://home.${host.domain}/bg/${builtins.head imageFiles}";
        blur = "sm";
        brightness = 25;
        opacity = 30;
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
      const bgEl = document.querySelector("#page_container > div:first-child");
      if (bgEl) {
        bgEl.style.backgroundImage = "url('/bg/" + pick + "')";
      }
    '';

    customCSS = ''
      @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;500;600;700;900&family=Rajdhani:wght@300;400;500;600;700&display=swap');

      :root {
        --synth-bg-deep:     #0d0221;
        --synth-bg-mid:      #1a1a2e;
        --synth-neon-pink:   #ff00ff;
        --synth-neon-cyan:   #00ffff;
        --synth-hot-purple:  #7209b7;
        --synth-magenta:     #b5179e;
        --synth-soft-pink:   #ff6b9d;
        --synth-blue:        #4cc9f0;
        --synth-card-bg:     rgba(13, 2, 33, 0.65);
        --synth-card-border: rgba(255, 0, 255, 0.2);
        --synth-card-hover:  rgba(114, 9, 183, 0.25);
        --synth-text:        #e0d0ff;
        --synth-text-muted:  #9d8cbf;
      }

      * {
        font-family: 'Rajdhani', 'Orbitron', sans-serif !important;
        -webkit-font-smoothing: antialiased;
      }

      body {
        background: var(--synth-bg-deep) !important;
      }

      .service-card {
        background: var(--synth-card-bg) !important;
        border: 1px solid var(--synth-card-border) !important;
        border-radius: 8px !important;
        box-shadow: 0 0 10px rgba(255, 0, 255, 0.4), 0 0 30px rgba(255, 0, 255, 0.1) !important;
        backdrop-filter: blur(12px) saturate(150%);
        -webkit-backdrop-filter: blur(12px) saturate(150%);
        transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94) !important;
      }

      .service-card:hover {
        background: var(--synth-card-hover) !important;
        border-color: var(--synth-neon-pink) !important;
        box-shadow:
          0 0 15px rgba(255, 0, 255, 0.5),
          0 0 45px rgba(255, 0, 255, 0.15),
          inset 0 1px 0 rgba(255, 0, 255, 0.1) !important;
        transform: translateY(-2px);
      }

      .service-name, .service-title {
        color: var(--synth-neon-cyan) !important;
        font-family: 'Orbitron', monospace !important;
        font-weight: 600 !important;
        font-size: 14px !important;
        letter-spacing: 0.5px;
        text-shadow: 0 0 8px rgba(0, 255, 255, 0.5);
      }

      .service-description {
        color: var(--synth-text-muted) !important;
        font-size: 12px !important;
      }

      .service-block, .bg-theme-200\/50 {
        background: rgba(114, 9, 183, 0.15) !important;
        border: 1px solid rgba(255, 0, 255, 0.15) !important;
        border-radius: 6px !important;
      }

      .service-block .uppercase {
        color: var(--synth-neon-pink) !important;
        font-family: 'Orbitron', monospace !important;
        text-shadow: 0 0 6px rgba(255, 0, 255, 0.4);
      }

      .service-block .font-thin {
        color: var(--synth-text) !important;
      }

      .service-group-name {
        color: var(--synth-neon-pink) !important;
        font-family: 'Orbitron', sans-serif !important;
        font-weight: 700 !important;
        text-transform: uppercase;
        letter-spacing: 2px;
        text-shadow:
          0 0 10px rgba(255, 0, 255, 0.6),
          0 0 30px rgba(255, 0, 255, 0.2);
        animation: neonPulse 3s ease-in-out infinite;
      }

      .service-group-icon > div {
        background: var(--synth-hot-purple) !important;
        box-shadow: 0 0 8px rgba(114, 9, 183, 0.5);
      }

      #information-widgets {
        border-color: rgba(255, 0, 255, 0.2) !important;
      }

      #information-widgets * {
        color: var(--synth-neon-cyan) !important;
      }

      .resource-usage {
        background: rgba(13, 2, 33, 0.5) !important;
        border-radius: 4px;
      }

      .resource-usage > div {
        background: linear-gradient(90deg, var(--synth-neon-pink), var(--synth-neon-cyan)) !important;
        box-shadow: 0 0 8px rgba(0, 255, 255, 0.4);
      }

      .information-widget-greeting span {
        font-family: 'Orbitron', sans-serif !important;
        color: var(--synth-neon-cyan) !important;
        text-shadow:
          0 0 10px rgba(0, 255, 255, 0.6),
          0 0 40px rgba(0, 255, 255, 0.2);
      }

      .ping-up, [class*="bg-emerald"] {
        background-color: var(--synth-neon-cyan) !important;
        box-shadow: 0 0 8px rgba(0, 255, 255, 0.6);
      }

      .ping-down, [class*="bg-rose"] {
        background-color: var(--synth-neon-pink) !important;
        box-shadow: 0 0 8px rgba(255, 0, 255, 0.6);
      }

      ::-webkit-scrollbar { width: 8px; }
      ::-webkit-scrollbar-track { background: var(--synth-bg-deep); }
      ::-webkit-scrollbar-thumb {
        background: linear-gradient(180deg, var(--synth-neon-pink), var(--synth-hot-purple));
        border-radius: 4px;
        box-shadow: 0 0 6px rgba(255, 0, 255, 0.3);
      }
      ::-webkit-scrollbar-thumb:hover {
        background: linear-gradient(180deg, var(--synth-neon-cyan), var(--synth-neon-pink));
      }

      @keyframes neonPulse {
        0%, 100% {
          text-shadow:
            0 0 5px rgba(255, 0, 255, 0.4),
            0 0 15px rgba(255, 0, 255, 0.2);
        }
        50% {
          text-shadow:
            0 0 10px rgba(255, 0, 255, 0.7),
            0 0 30px rgba(255, 0, 255, 0.3),
            0 0 50px rgba(255, 0, 255, 0.1);
        }
      }

      #footer svg {
        color: var(--synth-hot-purple) !important;
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
        search = {
          provider = "duckduckgo";
          target = "_blank";
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
