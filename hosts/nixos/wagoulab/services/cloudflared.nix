{ pkgs, host, ... }:

let
  # Cloudflare Tunnel config — routes all subdomains to Traefik inside the compose network.
  # The tunnel is locally-managed (credentials-file auth, not dashboard-token).
  # Uses HTTPS to Traefik to avoid the HTTP->HTTPS redirect loop.
  # noTLSVerify is safe here because the connection is internal (container-to-container).
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
  environment.etc."wagoulab/cloudflared-config.yml".source = configFile;

  systemd.tmpfiles.rules = [
    "d /var/lib/cloudflared 0755 root root -"
  ];
}
