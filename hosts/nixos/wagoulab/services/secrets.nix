{ config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      # Cloudflare credentials file — mounted directly into the cloudflared container.
      # Mode 0444 because cloudflared runs as nonroot (UID 65532) inside the container
      # and needs to read the bind-mounted file. The secret is on tmpfs (/run/secrets/).
      cloudflare-credentials.mode = "0444";

      # Compose service secrets (referenced in env templates below)
      cloudflare-dns-token.mode = "0400";
      cloudflare-tunnel-token.mode = "0400";

      vaultwarden-admin-token.mode = "0400";
      immich-api-key.mode = "0400";
      immich-db-username.mode = "0400";
      immich-db-password.mode = "0400";
      adguard-password.mode = "0400";
      jellyfin-api-key.mode = "0400";
      github-webhook-secret.mode = "0400";
      renovate-github-app-id.mode = "0400";
      renovate-github-app-key.mode = "0400";
      renovate-installation-id.mode = "0400";
      kitchenowl-jwt-secret.mode = "0400";
      authentik-secret-key.mode = "0400";
      authentik-postgres-password.mode = "0400";
      kitchenowl-oidc-client-secret.mode = "0400";
      seafile-mysql-root-password.mode = "0400";
      seafile-mysql-password.mode = "0400";
      seafile-jwt-key.mode = "0400";
      seafile-oauth-client-secret.mode = "0400";

      # Host-level secrets
      wagou-password-hash.neededForUsers = true;
      root-password-hash.neededForUsers = true;

      # rbw master password — used by custom pinentry for zero-touch vault unlock
      rbw-master-password = {
        mode = "0400";
        owner = "wagou";
      };
    };

    # Rendered env files consumed by containers via environmentFiles
    templates = {
      "traefik.env" = {
        content = "CF_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-dns-token}\n";
      };

      "vaultwarden.env" = {
        content = "ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}\n";
      };

      "immich.env" = {
        content = builtins.concatStringsSep "\n" [
          "DB_USERNAME=${config.sops.placeholder.immich-db-username}"
          "DB_PASSWORD=${config.sops.placeholder.immich-db-password}"
        ];
      };

      "immich-postgres.env" = {
        content = builtins.concatStringsSep "\n" [
          "POSTGRES_USER=${config.sops.placeholder.immich-db-username}"
          "POSTGRES_PASSWORD=${config.sops.placeholder.immich-db-password}"
        ];
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

      "webhook.env" = {
        content = "WEBHOOK_SECRET=${config.sops.placeholder.github-webhook-secret}\n";
      };

      "kitchenowl.env" = {
        content = builtins.concatStringsSep "\n" [
          "JWT_SECRET_KEY=${config.sops.placeholder.kitchenowl-jwt-secret}"
          "OIDC_CLIENT_SECRET=${config.sops.placeholder.kitchenowl-oidc-client-secret}"
        ];
      };

      "authentik.env" = {
        content = builtins.concatStringsSep "\n" [
          "AUTHENTIK_SECRET_KEY=${config.sops.placeholder.authentik-secret-key}"
          "AUTHENTIK_POSTGRESQL__PASSWORD=${config.sops.placeholder.authentik-postgres-password}"
        ];
      };

      "authentik-postgres.env" = {
        content = "POSTGRES_PASSWORD=${config.sops.placeholder.authentik-postgres-password}\n";
      };

      "seafile.env" = {
        content = builtins.concatStringsSep "\n" [
          "SEAFILE_MYSQL_DB_PASSWORD=${config.sops.placeholder.seafile-mysql-password}"
          "INIT_SEAFILE_MYSQL_ROOT_PASSWORD=${config.sops.placeholder.seafile-mysql-root-password}"
          "JWT_PRIVATE_KEY=${config.sops.placeholder.seafile-jwt-key}"
        ];
      };

      "seafile-db.env" = {
        content = "MYSQL_ROOT_PASSWORD=${config.sops.placeholder.seafile-mysql-root-password}\n";
      };

      "seahub_settings.py" = {
        content = builtins.concatStringsSep "\n" [
          "CSRF_TRUSTED_ORIGINS = ['https://disk.wagou.fr']"
          ""
          "# OAuth/OIDC via Authentik"
          "ENABLE_OAUTH = True"
          "OAUTH_CREATE_UNKNOWN_USER = True"
          "OAUTH_ACTIVATE_USER_AFTER_CREATION = True"
          "OAUTH_CLIENT_ID = 'seafile'"
          "OAUTH_CLIENT_SECRET = '${config.sops.placeholder.seafile-oauth-client-secret}'"
          "OAUTH_REDIRECT_URL = 'https://disk.wagou.fr/oauth/callback/'"
          "OAUTH_PROVIDER_DOMAIN = 'https://cipher.wagou.fr'"
          "OAUTH_AUTHORIZATION_URL = 'https://cipher.wagou.fr/application/o/authorize/'"
          "OAUTH_TOKEN_URL = 'https://cipher.wagou.fr/application/o/token/'"
          "OAUTH_USER_INFO_URL = 'https://cipher.wagou.fr/application/o/userinfo/'"
          "OAUTH_SCOPE = ['openid', 'profile', 'email']"
          "OAUTH_ATTRIBUTE_MAP = {"
          "    'email': (True, 'contact_email'),"
          "    'name': (False, 'name'),"
          "}"
          ""
          "# SSO via system browser for desktop/mobile clients"
          "CLIENT_SSO_VIA_LOCAL_BROWSER = True"
          ""
          "# SeaDoc"
          "ENABLE_SEADOC = True"
        ];
      };
    };
  };
}
