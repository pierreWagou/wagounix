{
  config,
  pkgs,
  host,
  ...
}:

let
  ws = import ../lib/web-service.nix { inherit config host; };

  cloudflareCredentials =
    if host.hostname == "wagou-clone" then
      config.sops.secrets.cloudflare-credentials-clone.path
    else
      config.sops.secrets.cloudflare-credentials-prime.path;

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
    exposeViaTraefik = false;
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
