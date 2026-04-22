{ config, host, ... }:

{
  services.opencloud = {
    enable = true;
    url = "https://cloud.${host.domain}";
    address = "127.0.0.1";
    port = 9200;

    environment = {
      # TLS is terminated by Cloudflare (public) and Caddy (local).
      # OpenCloud runs behind the reverse proxy on localhost only.
      OC_INSECURE = "true";
      PROXY_TLS = "false";
    };

    environmentFile = config.sops.templates."opencloud.env".path;

    settings = {
      proxy.enable_basic_auth = true;
    };
  };

  systemd.services.opencloud.restartTriggers = [
    config.sops.templates."opencloud.env".content
  ];
}
