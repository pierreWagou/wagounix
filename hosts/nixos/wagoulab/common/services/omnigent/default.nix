{
  config,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;
  ws = import ../lib/web-service.nix { inherit config host; };
  server = ws.mkWebService {
    name = "omnigent";
    subdomain = "ai";
    image = "ghcr.io/omnigent-ai/omnigent-server:latest";
    port = 8000;
    # Use host DNS (AdGuard Home) so auth.wagou.fr resolves to the server IP
    # instead of Cloudflare — the JWKS endpoint is fetched server-side and
    # must reach Authentik directly, not through the Cloudflare tunnel.
    dns = [ host.serverIP ];
    env = {
      OMNIGENT_BUILTIN_AGENT_DIRS = "/agents/wagou:/agents/alan";
    };
    volumes = [
      "/var/lib/omnigent:/data"
      "/home/${host.username}/.omnigent/agents:/agents:ro"
    ];
    environmentFiles = [ config.sops.templates."omnigent.env".path ];
    extraNetworks = [ networks.omnigent-internal.ref ];
    unitConfig = {
      Requires = [ containers.omnigent-postgres.ref ];
      After = [ containers.omnigent-postgres.ref ];
    };
  };
in
{
  sops = {
    secrets = {
      omnigent-postgres-password = {
        sopsFile = ./secrets.yaml;
        mode = "0444";
      };

      omnigent-cookie-secret = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };

      omnigent-oidc-client-secret = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "omnigent-postgres.env" = {
        content = builtins.concatStringsSep "\n" [
          "POSTGRES_DB=omnigent"
          "POSTGRES_USER=omnigent"
          "POSTGRES_PASSWORD=${config.sops.placeholder.omnigent-postgres-password}"
        ];
      };

      "omnigent.env" = {
        content = builtins.concatStringsSep "\n" [
          "DATABASE_URL=postgresql+psycopg://omnigent:${config.sops.placeholder.omnigent-postgres-password}@omnigent-postgres:5432/omnigent"
          "ARTIFACT_DIR=/data/artifacts"
          "HOST=0.0.0.0"
          "PORT=8000"
          "OMNIGENT_AUTH_ENABLED=1"
          "OMNIGENT_AUTH_PROVIDER=oidc"
          "OMNIGENT_OIDC_ISSUER=https://auth.${host.domain}/application/o/omnigent/"
          "OMNIGENT_OIDC_CLIENT_ID=omnigent"
          "OMNIGENT_OIDC_CLIENT_SECRET=${config.sops.placeholder.omnigent-oidc-client-secret}"
          "OMNIGENT_OIDC_COOKIE_SECRET=${config.sops.placeholder.omnigent-cookie-secret}"
          "OMNIGENT_OIDC_SCOPES=openid email profile"
          "OMNIGENT_OIDC_SESSION_TTL_HOURS=8"
          "OMNIGENT_OIDC_SKIP_EMAIL_VERIFICATION=1"
          "OMNIGENT_DOMAIN=ai.${host.domain}"
        ];
      };
    };
  };

  # OmniGent-internal network for Postgres ↔ Server traffic (not exposed to Traefik)
  virtualisation.quadlet.networks.omnigent-internal = { };

  virtualisation.quadlet.containers = {
    omnigent-server.containerConfig = server.containerConfig;
    omnigent-server.unitConfig = server.unitConfig;
    omnigent-postgres = {
      containerConfig = {
        image = "postgres:16-alpine";
        noNewPrivileges = true;
        networks = [ networks.omnigent-internal.ref ];
        volumes = [ "/var/lib/omnigent-postgres:/var/lib/postgresql/data" ];
        environmentFiles = [ config.sops.templates."omnigent-postgres.env".path ];
        shmSize = "256m";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/omnigent 0755 root root -"
    "d /var/lib/omnigent-postgres 0755 root root -"
  ];
}
