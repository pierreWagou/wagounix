{ config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      # Cloudflare credentials file — mounted directly into the cloudflared container
      cloudflare-credentials.mode = "0444";

      # Compose service secrets (referenced in env templates below)
      cloudflare-dns-token.mode = "0400";
      cloudflare-tunnel-token.mode = "0400";
      opencloud-admin-password.mode = "0400";
      vaultwarden-admin-token.mode = "0400";
      immich-api-key.mode = "0400";
      adguard-password.mode = "0400";
      jellyfin-api-key.mode = "0400";

      # Host-level secrets
      wagou-password-hash.neededForUsers = true;
      root-password-hash.neededForUsers = true;
    };

    # Rendered env files consumed by podman-compose containers via env_file
    templates = {
      "traefik.env" = {
        content = "CF_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-dns-token}\n";
      };

      "opencloud.env" = {
        content = "IDM_ADMIN_PASSWORD=${config.sops.placeholder.opencloud-admin-password}\n";
      };

      "vaultwarden.env" = {
        content = "ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}\n";
      };

      "homepage.env" = {
        content = builtins.concatStringsSep "\n" [
          "HOMEPAGE_VAR_IMMICH_API_KEY=${config.sops.placeholder.immich-api-key}"
          "HOMEPAGE_VAR_ADGUARD_USER=admin"
          "HOMEPAGE_VAR_ADGUARD_PASS=${config.sops.placeholder.adguard-password}"
          "HOMEPAGE_VAR_CF_API_TOKEN=${config.sops.placeholder.cloudflare-tunnel-token}"
          "HOMEPAGE_VAR_JELLYFIN_API_KEY=${config.sops.placeholder.jellyfin-api-key}"
        ];
      };
    };
  };
}
