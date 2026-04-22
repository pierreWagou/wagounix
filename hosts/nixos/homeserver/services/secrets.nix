{ config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      cloudflared-token = {
        mode = "0400";
      };
      opencloud-admin-password = {
        mode = "0400";
      };
      vaultwarden-admin-token = {
        mode = "0400";
      };
    };

    templates."opencloud.env" = {
      owner = "opencloud";
      content = "IDM_ADMIN_PASSWORD=${config.sops.placeholder.opencloud-admin-password}\n";
    };

    templates."vaultwarden.env" = {
      owner = "vaultwarden";
      content = "ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}\n";
    };
  };
}
