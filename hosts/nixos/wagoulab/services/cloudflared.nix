{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;

  # Tunnel config — two sets of ingress rules:
  #   1. Service subdomains → NixOS Traefik via HTTPS on the host LAN IP.
  #      noTLSVerify is safe because this is an internal connection.
  #   2. App subdomains → Dokploy Traefik via HTTP on the host loopback (127.0.0.1:8080).
  #      Cloudflare handles TLS at the edge; Dokploy Traefik receives plain HTTP.
  configFile = pkgs.writeText "cloudflared-config.yml" (
    builtins.toJSON {
      tunnel = host.cloudflareTunnelId;
      credentials-file = "/etc/cloudflared/credentials.json";
      ingress =
        (map (sub: {
          hostname = "${sub}.${host.domain}";
          service = "https://${host.serverIP}:443";
          originRequest.noTLSVerify = true;
        }) host.serviceTunnelSubdomains)
        ++ (map (sub: {
          hostname = "${sub}.${host.domain}";
          service = "http://host.containers.internal:8080";
        }) host.appTunnelSubdomains)
        ++ [ { service = "http_status:404"; } ];
    }
  );
in
{
  virtualisation.quadlet.containers.cloudflared = {
    containerConfig = {
      image = "cloudflare/cloudflared:2026.5.1";
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
