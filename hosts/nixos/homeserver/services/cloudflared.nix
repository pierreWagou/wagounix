{
  config,
  pkgs,
  ...
}:

{
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
    serviceConfig = {
      ExecStart = "/bin/sh -c '${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token $(cat ${config.sops.secrets.cloudflared-token.path})'";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
