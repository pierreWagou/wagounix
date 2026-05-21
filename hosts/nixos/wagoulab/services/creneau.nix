{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet.containers.creneau = {
    containerConfig = {
      image = "ghcr.io/pierrewagou/creneau:latest";
      podmanArgs = [ "--pull=always" ];
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/creneau:/app/ data"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.creneau.rule" = "Host(`creneau.${host.domain}`)";
        "traefik.http.routers.creneau.entrypoints" = "websecure";
        "traefik.http.routers.creneau.tls" = "true";
        "traefik.http.routers.creneau.middlewares" = "secure-headers@file";
        "traefik.http.services.creneau.loadbalancer.server.port" = "3000";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/creneau 0755 root root -"
  ];
}
