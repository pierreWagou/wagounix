{ config, host, ... }:

{
  services.caddy = {
    enable = true;

    virtualHosts = {
      "http://vault.${host.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT} {
          header_up X-Real-IP {remote_host}
        }
      '';

      "http://pixel.${host.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.immich.port}
      '';

      "http://cloud.${host.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.opencloud.port} {
          header_up X-Forwarded-Proto https
        }
      '';

      "http://${host.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
      '';

      "http://home.${host.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
      '';
    };
  };
}
