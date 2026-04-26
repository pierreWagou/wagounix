{ config, host, ... }:

{
  virtualisation.oci-containers.containers.opencloud = {
    image = "opencloudeu/opencloud-rolling:latest";
    ports = [ "127.0.0.1:9200:9200" ];
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
      IDM_CREATE_DEMO_USERS = "false";
      PROXY_ENABLE_BASIC_AUTH = "true";
    };
    environmentFiles = [
      config.sops.templates."opencloud.env".path
    ];
    # First boot: init generates internal secrets, then start the server.
    # Subsequent boots: init is a no-op (|| true), server starts normally.
    entrypoint = "/bin/sh";
    cmd = [
      "-c"
      "opencloud init || true; opencloud server"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/opencloud 0755 1000 1000 -"
    "d /var/lib/opencloud/config 0755 1000 1000 -"
    "d /var/lib/opencloud/data 0755 1000 1000 -"
  ];
}
