{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet.containers.opencloud = {
    containerConfig = {
      image = "opencloudeu/opencloud-rolling:7.0.0";
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/opencloud/config:/etc/opencloud"
        "/var/lib/opencloud/data:/var/lib/opencloud"
      ];
      environments = {
        OC_URL = "https://cloud.${host.domain}";
        # OC_INSECURE: required because OC_URL is HTTPS but the service listens on
        # plain HTTP behind Traefik. Without this, OpenCloud's internal health checks
        # against its own URL would fail TLS verification.
        OC_INSECURE = "true";
        PROXY_TLS = "false";
        PROXY_HTTP_ADDR = "0.0.0.0:9200";
        PROXY_ENABLE_BASIC_AUTH = "true";
      };
      environmentFiles = [ config.sops.templates."opencloud.env".path ];
      entrypoint = "/bin/sh";
      exec = [
        "-c"
        "opencloud init || true; exec opencloud server"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.opencloud.rule" = "Host(`cloud.${host.domain}`)";
        "traefik.http.routers.opencloud.entrypoints" = "websecure";
        "traefik.http.routers.opencloud.tls" = "true";
        "traefik.http.routers.opencloud.middlewares" = "secure-headers@file";
        "traefik.http.services.opencloud.loadbalancer.server.port" = "9200";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/opencloud 0755 1000 1000 -"
    "d /var/lib/opencloud/config 0755 1000 1000 -"
    "d /var/lib/opencloud/data 0755 1000 1000 -"
  ];
}
