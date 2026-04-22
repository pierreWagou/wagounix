{
  config,
  pkgs,
  ...
}:

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
      config.sops.secrets.cloudflared-token.path
    ];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file ${config.sops.secrets.cloudflared-token.path}";
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
