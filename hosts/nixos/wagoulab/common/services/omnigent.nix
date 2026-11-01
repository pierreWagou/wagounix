{
  config,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;
  ws = import ./lib/web-service.nix { inherit config host; };
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
