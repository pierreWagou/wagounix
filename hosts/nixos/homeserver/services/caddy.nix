{
  config,
  pkgs,
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
  services.caddy = {
    enable = true;

    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
      hash = "sha256-Zls+5kWd/JSQsmZC4SRQ/WS+pUcRolNaaI7UQoPzJA0=";
    };

    globalConfig = ''
      email pierre.romon@gmail.com
      acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      auto_https disable_redirects
    '';

    virtualHosts = {
      "vault.${host.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT} {
          header_up X-Real-IP {remote_host}
        }
      '';

      "pixel.${host.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.immich.port}
      '';

      "cloud.${host.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.opencloud.port} {
          header_up X-Forwarded-Proto https
        }
      '';

      "${host.domain}".extraConfig = homepageConfig;

      "home.${host.domain}".extraConfig = homepageConfig;
    };
  };

  # Inject Cloudflare DNS API token for ACME DNS-01 challenge
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates."caddy.env".path;
}
