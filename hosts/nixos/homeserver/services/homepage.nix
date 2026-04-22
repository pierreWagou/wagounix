{ config, host, ... }:

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
      title = "Wagou Homelab";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      statusStyle = "dot";
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
