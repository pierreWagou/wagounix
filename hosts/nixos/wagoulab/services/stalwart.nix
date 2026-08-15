{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet.containers.stalwart = {
    containerConfig = {
      image = "stalwartlabs/stalwart:v0.16";
      noNewPrivileges = true;
      addCapabilities = [ "NET_BIND_SERVICE" ];
      networks = [ networks.proxy.ref ];
      publishPorts = [
        "0.0.0.0:25:25/tcp"
        "0.0.0.0:465:465/tcp"
        "0.0.0.0:587:587/tcp"
        "0.0.0.0:143:143/tcp"
        "0.0.0.0:993:993/tcp"
        "0.0.0.0:4190:4190/tcp"
      ];
      volumes = [
        "/var/lib/stalwart:/var/lib/stalwart"
        "/var/lib/stalwart-config:/etc/stalwart"
      ];
      environmentFiles = [ config.sops.templates."stalwart.env".path ];
      environments = {
        STALWART_HOSTNAME = "mail.${host.domain}";
        STALWART_PUBLIC_URL = "https://mailbox.${host.domain}";
        STALWART_RECOVERY_MODE = "1";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.stalwart.rule" = "Host(`mailbox.${host.domain}`)";
        "traefik.http.routers.stalwart.entrypoints" = "websecure";
        "traefik.http.routers.stalwart.tls" = "true";
        "traefik.http.routers.stalwart.middlewares" = "secure-headers@file";
        "traefik.http.services.stalwart.loadbalancer.server.port" = "8080";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/stalwart 0755 2000 2000 -"
    "d /var/lib/stalwart-config 0755 2000 2000 -"
  ];
}
