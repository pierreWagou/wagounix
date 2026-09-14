{
  config,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;
in
{
  # OmniGent-internal network for Postgres ↔ Server traffic (not exposed to Traefik)
  virtualisation.quadlet.networks.omnigent-internal = { };

  virtualisation.quadlet.containers = {
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

    omnigent-server = {
      containerConfig = {
        image = "ghcr.io/omnigent-ai/omnigent-server:latest";
        noNewPrivileges = true;
        # Use host DNS (AdGuard Home) so auth.wagou.fr resolves to the server IP
        # instead of Cloudflare — the JWKS endpoint is fetched server-side and
        # must reach Authentik directly, not through the Cloudflare tunnel.
        dns = [ host.serverIP ];
        networks = [
          networks.proxy.ref
          networks.omnigent-internal.ref
        ];
        volumes = [
          "/var/lib/omnigent:/data"
          "/home/${host.username}/.omnigent/agents:/agents:ro"
        ];
        environments = {
          OMNIGENT_BUILTIN_AGENT_DIRS = "/agents/wagou:/agents/alan";
        };
        environmentFiles = [ config.sops.templates."omnigent.env".path ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.omnigent.rule" = "Host(`ai.${host.domain}`)";
          "traefik.http.routers.omnigent.entrypoints" = "websecure";
          "traefik.http.routers.omnigent.tls" = "true";
          "traefik.http.routers.omnigent.middlewares" = "secure-headers@file";
          "traefik.http.services.omnigent.loadbalancer.server.port" = "8000";
        };
      };
      unitConfig = {
        Requires = [ containers.omnigent-postgres.ref ];
        After = [ containers.omnigent-postgres.ref ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/omnigent 0755 root root -"
    "d /var/lib/omnigent-postgres 0755 root root -"
  ];
}
