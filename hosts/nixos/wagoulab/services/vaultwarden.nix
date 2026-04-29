{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet.containers.vaultwarden = {
    containerConfig = {
      image = "vaultwarden/server:latest";
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/vaultwarden:/data"
      ];
      environments = {
        DOMAIN = "https://vault.${host.domain}";
        SIGNUPS_ALLOWED = "false";
        IP_HEADER = "X-Real-IP";
      };
      environmentFiles = [ config.sops.templates."vaultwarden.env".path ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.vaultwarden.rule" = "Host(`vault.${host.domain}`)";
        "traefik.http.routers.vaultwarden.entrypoints" = "websecure";
        "traefik.http.routers.vaultwarden.tls" = "true";
        "traefik.http.routers.vaultwarden.middlewares" = "secure-headers@file";
        "traefik.http.services.vaultwarden.loadbalancer.server.port" = "80";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden 0755 root root -"
    "d /var/backup/vaultwarden 0755 root root -" # for planned borgbackup/restic service
  ];
}
