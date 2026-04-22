{ config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      cloudflared-token = {
        mode = "0400";
        owner = "cloudflared";
        group = "cloudflared";
      };
      opencloud-admin-password = {
        mode = "0400";
      };
      vaultwarden-admin-token = {
        mode = "0400";
      };
      wagou-password-hash = {
        neededForUsers = true;
      };
      root-password-hash = {
        neededForUsers = true;
      };
      immich-api-key = {
        mode = "0400";
      };
      adguard-password = {
        mode = "0400";
      };
      cloudflare-api-token = {
        mode = "0400";
      };
    };

    templates = {
      "opencloud.env" = {
        owner = "opencloud";
        content = "IDM_ADMIN_PASSWORD=${config.sops.placeholder.opencloud-admin-password}\n";
      };

      "vaultwarden.env" = {
        owner = "vaultwarden";
        content = "ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}\n";
      };

      "homepage.env" = {
        content = builtins.concatStringsSep "\n" [
          "HOMEPAGE_VAR_IMMICH_API_KEY=${config.sops.placeholder.immich-api-key}"
          "HOMEPAGE_VAR_ADGUARD_USER=admin"
          "HOMEPAGE_VAR_ADGUARD_PASS=${config.sops.placeholder.adguard-password}"
          "HOMEPAGE_VAR_CF_API_TOKEN=${config.sops.placeholder.cloudflare-api-token}"
        ];
      };
    };
  };
}
