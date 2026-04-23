{
  config,
  host,
  ...
}:

let
  homepageImages = ./homepage-images;

  # HSTS header — tells browsers to always use HTTPS for *.wagou.fr
  hsts = ''header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"'';

  homepageConfig = ''
    ${hsts}
    handle_path /bg/* {
      file_server
      root * ${homepageImages}
    }
    handle {
      reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
    }
  '';

  vaultConfig = ''
    ${hsts}
    reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT} {
      header_up X-Real-IP {remote_host}
    }
  '';

  pixelConfig = ''
    ${hsts}
    reverse_proxy 127.0.0.1:${toString config.services.immich.port}
  '';

  cloudConfig = ''
    ${hsts}
    reverse_proxy 127.0.0.1:${toString config.services.opencloud.port} {
      header_up X-Forwarded-Proto https
    }
  '';

  guardConfig = ''
    ${hsts}
    reverse_proxy 127.0.0.1:${toString config.services.adguardhome.port}
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

    virtualHosts = {
      "vault.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = vaultConfig;
      };
      "pixel.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = pixelConfig;
      };
      "cloud.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = cloudConfig;
      };
      "${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = homepageConfig;
      };
      "home.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = homepageConfig;
      };
      "guard.${host.domain}" = {
        useACMEHost = host.domain;
        extraConfig = guardConfig;
      };
    };
  };
}
