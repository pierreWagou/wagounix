{ config, host, ... }:

let
  port = host.opencloudPort;
in
{
  virtualisation.oci-containers.containers.opencloud = {
    image = "opencloudeu/opencloud-rolling:latest";
    ports = [ "127.0.0.1:${toString port}:9200" ];
    volumes = [
      "/var/lib/opencloud/config:/etc/opencloud"
      "/var/lib/opencloud/data:/var/lib/opencloud"
    ];
    environment = {
      OC_URL = "https://cloud.${host.domain}";
      # TLS is terminated by Cloudflare (public) and Caddy (local).
      # OpenCloud runs behind the reverse proxy on localhost only.
      OC_INSECURE = "true";
      PROXY_TLS = "false";
      PROXY_HTTP_ADDR = "0.0.0.0:9200";
      PROXY_ENABLE_BASIC_AUTH = "true";
    };
    environmentFiles = [
      config.sops.templates."opencloud.env".path
    ];
    # Init generates secrets/config on first run (no-op if config exists), then starts the server
    cmd = [
      "sh"
      "-c"
      "opencloud init || true; exec opencloud server"
    ];
  };

  systemd.services.podman-opencloud.restartTriggers = [
    config.sops.templates."opencloud.env".content
  ];

  # OpenCloud container runs as UID 1000 by default
  systemd.tmpfiles.rules = [
    "d /var/lib/opencloud 0755 1000 1000 -"
    "d /var/lib/opencloud/config 0755 1000 1000 -"
    "d /var/lib/opencloud/data 0755 1000 1000 -"
  ];
}
