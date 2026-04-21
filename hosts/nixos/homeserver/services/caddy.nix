{ config, ... }:

{
  services.caddy = {
    enable = true;

    virtualHosts = {
      "http://vault.wagou.fr".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT} {
          header_up X-Real-IP {remote_host}
        }
      '';

      "http://pixel.wagou.fr".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.immich.port}
      '';

      "http://cloud.wagou.fr".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.opencloud.port}
      '';
    };
  };
}
