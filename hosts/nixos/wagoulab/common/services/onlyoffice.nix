{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet.containers.onlyoffice = {
    containerConfig = {
      # Pinned below latest: Seafile's own docs reference 8.1.x; 9.4 is
      # baked since May 2026 (Docs 10.x is weeks old). Revisit on upgrade.
      image = "docker.io/onlyoffice/documentserver:9.4";
      noNewPrivileges = true;
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/onlyoffice/logs:/var/log/onlyoffice"
        "/var/lib/onlyoffice/data:/var/www/onlyoffice/Data"
        "/var/lib/onlyoffice/lib:/var/lib/onlyoffice"
        "/var/lib/onlyoffice/db:/var/lib/postgresql"
      ];
      environments = {
        JWT_ENABLED = "true";
      };
      environmentFiles = [ config.sops.templates."onlyoffice.env".path ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.onlyoffice.rule" = "Host(`docs.${host.domain}`)";
        "traefik.http.routers.onlyoffice.entrypoints" = "websecure";
        "traefik.http.routers.onlyoffice.tls" = "true";
        "traefik.http.routers.onlyoffice.middlewares" = "secure-headers@file";
        "traefik.http.services.onlyoffice.loadbalancer.server.port" = "80";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/onlyoffice 0755 root root -"
    "d /var/lib/onlyoffice/logs 0755 root root -"
    "d /var/lib/onlyoffice/data 0755 root root -"
    "d /var/lib/onlyoffice/lib 0755 root root -"
    "d /var/lib/onlyoffice/db 0755 root root -"
  ];
}
