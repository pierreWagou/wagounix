{ config, ... }:

{
  services.opencloud = {
    enable = true;
    url = "https://cloud.wagou.fr";
    address = "127.0.0.1";
    port = 9200;

    environment = {
      OC_INSECURE = "true";
      PROXY_TLS = "false";
    };

    environmentFile = config.sops.templates."opencloud.env".path;

    settings = {
      proxy.enable_basic_auth = true;
    };
  };

  # Ensure sops secrets are decrypted before OpenCloud starts
  systemd.services.opencloud = {
    after = [ "sops-nix.service" ];
    requires = [ "sops-nix.service" ];
  };
}
