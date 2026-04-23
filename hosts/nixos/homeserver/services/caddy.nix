{
  config,
  host,
  ...
}:

let
  homepageImages = ./homepage-images;
  homepageConfig = ''
    handle_path /bg/* {
      file_server
      root * ${homepageImages}
    }
    handle {
      reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
    }
  '';
in
{
  # Wildcard certificate via Let's Encrypt DNS-01 challenge (Cloudflare)
  security.acme = {
    acceptTerms = true;
    defaults.email = "pierre.romon@gmail.com";

    certs."${host.domain}" = {
      domain = "*.${host.domain}";
      extraDomainNames = [ host.domain ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.sops.templates."caddy.env".path;
      reloadServices = [ "caddy.service" ];
      inherit (config.services.caddy) group;
    };
  };

  # Grant caddy user access to ACME certs
  users.users.${config.services.caddy.user}.extraGroups = [ "acme" ];

  services.caddy = {
    enable = true;

    globalConfig = ''
      auto_https disable_redirects
    '';

    virtualHosts = {
      "vault.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT} {
            header_up X-Real-IP {remote_host}
          }
        '';
      };

      "pixel.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.immich.port}
        '';
      };

      "cloud.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.opencloud.port} {
            header_up X-Forwarded-Proto https
          }
        '';
      };

      "${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = homepageConfig;
      };

      "home.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = homepageConfig;
      };
    };
  };
}
