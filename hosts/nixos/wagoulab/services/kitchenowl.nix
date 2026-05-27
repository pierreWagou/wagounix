{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet.containers.kitchenowl = {
    containerConfig = {
      image = "tombursch/kitchenowl:v0.7.8";
      noNewPrivileges = true;
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/kitchenowl:/data"
      ];
      environments = {
        OPEN_REGISTRATION = "true";
        OIDC_ISSUER = "https://cipher.${host.domain}/application/o/kitchen-owl/";
        OIDC_CLIENT_ID = "kitchenowl";
        FRONT_URL = "https://cabas.${host.domain}";
      };
      environmentFiles = [ config.sops.templates."kitchenowl.env".path ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.kitchenowl.rule" = "Host(`cabas.${host.domain}`)";
        "traefik.http.routers.kitchenowl.entrypoints" = "websecure";
        "traefik.http.routers.kitchenowl.tls" = "true";
        "traefik.http.routers.kitchenowl.middlewares" = "secure-headers@file";
        "traefik.http.services.kitchenowl.loadbalancer.server.port" = "8080";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kitchenowl 0755 root root -"
  ];
}
