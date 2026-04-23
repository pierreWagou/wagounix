{
  config,
  pkgs,
  host,
  ...
}:

let
  d = host.domain;

  configFile = pkgs.writeText "cloudflared-config.yml" ''
    tunnel: ${host.cloudflareTunnelId}
    credentials-file: ${config.sops.secrets.cloudflare-credentials.path}
    ingress:
      - hostname: vault.${d}
        service: https://localhost:443
        originRequest:
          originServerName: ${d}
      - hostname: pixel.${d}
        service: https://localhost:443
        originRequest:
          originServerName: ${d}
      - hostname: cloud.${d}
        service: https://localhost:443
        originRequest:
          originServerName: ${d}
      - hostname: home.${d}
        service: https://localhost:443
        originRequest:
          originServerName: ${d}
      - hostname: guard.${d}
        service: https://localhost:443
        originRequest:
          originServerName: ${d}
      - service: http_status:404
  '';
in
{
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = { };

  # Cloudflare Tunnel — secure remote access without opening ports
  systemd.services.cloudflared-tunnel = {
    description = "Cloudflare Tunnel";
    after = [
      "network-online.target"
    ];
    wants = [
      "network-online.target"
    ];
    wantedBy = [
      "multi-user.target"
    ];
    restartTriggers = [
      config.sops.secrets.cloudflare-credentials.path
      configFile
    ];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared --config ${configFile} tunnel --no-autoupdate run";
      Restart = "on-failure";
      RestartSec = 5;
      User = "cloudflared";
      Group = "cloudflared";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };
}
