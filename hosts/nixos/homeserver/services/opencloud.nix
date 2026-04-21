_: {
  services.opencloud = {
    enable = true;
    url = "https://cloud.wagou.fr";
    address = "127.0.0.1";
    port = 9200;

    environment = {
      OC_INSECURE = "true";
      PROXY_TLS = "false";
    };

    # Secrets stored at /var/lib/opencloud-secrets/opencloud.env on the server
    environmentFile = "/var/lib/opencloud-secrets/opencloud.env";

    settings = {
      proxy.enable_basic_auth = true;
    };
  };
}
