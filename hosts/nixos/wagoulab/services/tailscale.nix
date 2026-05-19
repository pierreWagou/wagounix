{ pkgs, host, ... }:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--advertise-routes=${host.lanSubnet}"
      "--accept-dns=false" # don't override DNS — the server runs AdGuard Home
    ];
  };

  # Tailscale needs IP forwarding for subnet routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # UDP GRO forwarding optimization for subnet router throughput
  # See: https://tailscale.com/s/ethtool-config-udp-gro
  systemd.services.tailscale-ethtool = {
    description = "Configure UDP GRO forwarding for Tailscale subnet routing";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K ${host.networkInterface} rx-udp-gro-forwarding on rx-gro-list off";
      RemainAfterExit = true;
    };
  };
}
