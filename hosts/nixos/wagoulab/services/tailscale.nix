_: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--advertise-routes=192.168.68.0/24"
      "--accept-dns=false" # don't override DNS — the server runs AdGuard Home
    ];
  };

  # Tailscale needs IP forwarding for subnet routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
