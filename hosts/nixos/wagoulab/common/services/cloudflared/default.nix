{
  config,
  pkgs,
  host,
  ...
}:

let
  ws = import ../lib/web-service.nix { inherit config host; };

  # Host-specific Cloudflare credentials
  cloudflareCredentials =
    if host.hostname == "wagou-clone" then
      config.sops.secrets.cloudflare-credentials-clone.path
    else
      config.sops.secrets.cloudflare-credentials-prime.path;

  # Tunnel config — routes all subdomains to NixOS Traefik.
  # NixOS Traefik dispatches: service subdomains to Podman containers,
  # app subdomains to Dokploy Traefik (127.0.0.1:8080).
  # Uses HTTPS with noTLSVerify (internal connection, cert is self-signed).
  configFile = pkgs.writeText "cloudflared-config.yml" (
    builtins.toJSON {
      tunnel = host.cloudflareTunnelId;
      credentials-file = "/etc/cloudflared/credentials.json";
      ingress =
        (map (sub: {
          hostname = "${sub}.${host.domain}";
          service = "https://${host.serverIP}:443";
          originRequest.noTLSVerify = true;
        }) (host.serviceTunnelSubdomains ++ host.appTunnelSubdomains))
        ++ [ { service = "http_status:404"; } ];
    }
  );
  tunnel = ws.mkWebService {
    name = "cloudflared";
    exposeViaTraefik = false; # the tunnel feeds Traefik, not the other way around
    image = "docker.io/cloudflare/cloudflared:2026.5.1";
    volumes = [
      "${configFile}:/etc/cloudflared/config.yml:ro"
      "${cloudflareCredentials}:/etc/cloudflared/credentials.json:ro"
    ];
    exec = [
      "tunnel"
      "--config"
      "/etc/cloudflared/config.yml"
      "--no-autoupdate"
      "run"
    ];
  };
in
{
  # Cloudflare credentials file — mounted directly into the cloudflared container.
  # Mode 0444 because cloudflared runs as nonroot (UID 65532) inside the container
  # and needs to read the bind-mounted file. The secret is on tmpfs (/run/secrets/).
  # Host-specific: wagou-prime uses "cloudflare-credentials-prime", wagou-clone uses "cloudflare-credentials-clone".
  sops = {
    secrets = {
      cloudflare-credentials-prime = {
        sopsFile = ./secrets.yaml;
        mode = "0444";
      };

      cloudflare-credentials-clone = {
        sopsFile = ./secrets.yaml;
        mode = "0444";
      };
    };
  };

  virtualisation.quadlet.containers.cloudflared.containerConfig = tunnel.containerConfig;
}
