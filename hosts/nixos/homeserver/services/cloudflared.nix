{
  config,
  pkgs,
  host,
  ...
}:

let
  tunnelId = host.cloudflareTunnelId;

  configFile = pkgs.writeText "cloudflared-config.yml" ''
    tunnel: ${tunnelId}
    credentials-file: ${config.sops.secrets.cloudflare-credentials.path}

    ingress:
      - hostname: vault.${host.domain}
        service: https://localhost:443
        originRequest:
          originServerName: ${host.domain}
      - hostname: pixel.${host.domain}
        service: https://localhost:443
        originRequest:
          originServerName: ${host.domain}
      - hostname: cloud.${host.domain}
        service: https://localhost:443
        originRequest:
          originServerName: ${host.domain}
      - hostname: home.${host.domain}
        service: https://localhost:443
        originRequest:
          originServerName: ${host.domain}
      - hostname: ${host.domain}
        service: https://localhost:443
        originRequest:
          originServerName: ${host.domain}
      - hostname: guard.${host.domain}
        service: https://localhost:443
        originRequest:
          originServerName: ${host.domain}
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
