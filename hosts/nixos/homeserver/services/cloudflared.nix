{ pkgs, ... }:

{
  # Cloudflare Tunnel — secure remote access without opening ports
  # Token is stored at /var/lib/cloudflared/tunnel-token on the server
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
      ExecStart = "/bin/sh -c '${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token $(cat /var/lib/cloudflared/tunnel-token)'";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
