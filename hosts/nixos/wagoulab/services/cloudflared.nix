{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;

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
in
{
  virtualisation.quadlet.containers.cloudflared = {
    containerConfig = {
      image = "cloudflare/cloudflared:2026.6.1";
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
