{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;

  # Tunnel config — routes all subdomains to Traefik inside the Podman network.
  # Uses HTTPS to avoid the HTTP->HTTPS redirect loop.
  # noTLSVerify is safe because the connection is internal (container-to-container).
  configFile = pkgs.writeText "cloudflared-config.yml" (
    builtins.toJSON {
      tunnel = host.cloudflareTunnelId;
      credentials-file = "/etc/cloudflared/credentials.json";
      ingress =
        (map (sub: {
          hostname = "${sub}.${host.domain}";
          service = "https://traefik:443";
          originRequest.noTLSVerify = true;
        }) host.tunnelSubdomains)
        ++ [ { service = "http_status:404"; } ];
    }
  );
in
{
  virtualisation.quadlet.containers.cloudflared = {
    containerConfig = {
      image = "cloudflare/cloudflared:latest";
      noNewPrivileges = true;
      networks = [ networks.proxy.ref ];
      volumes = [
        "${configFile}:/etc/cloudflared/config.yml:ro"
        "${config.sops.secrets.cloudflare-credentials.path}:/etc/cloudflared/credentials.json:ro"
      ];
      exec = [
        "tunnel"
        "--config"
        "/etc/cloudflared/config.yml"
        "--no-autoupdate"
        "run"
      ];
    };
  };
}
