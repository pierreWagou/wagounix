rec {
  username = "wagou";
  homeDir = "/home/${username}";
  hostname = "wagoulab";
  domain = "wagou.fr";
  serverIP = "192.168.68.65";
  tailscaleIP = "100.68.157.70";
  networkInterface = "enp170s0";
  lanSubnet = "192.168.68.0/24";
  renderGroupGid = "303";
  timezone = "Europe/Paris";
  acmeEmail = "pierre.romon@gmail.com";
  adminEmail = "pierre.romon@gmail.com";
  cloudflareAccountId = "65b2dca00576549f065820b1cd5c76c9";
  cloudflareTunnelId = "77f1d05e-ce21-4a09-8229-13f173b38525";

  # Geographic coordinates (for weather widgets etc.)
  latitude = 48.8566;
  longitude = 2.3522;

  # Shared container image versions
  valkeyImage = "docker.io/valkey/valkey:9.1.0";

  # Podman network CIDRs — used by services that need to trust proxied requests
  podmanCIDRs = [
    "10.89.0.0/16"
    "172.16.0.0/12"
  ];

  # Service ports (single source of truth — referenced by traefik, firewall, and service configs)
  ports = {
    ttyd = 7681;
    webhook = 9000;
  };

  # Subdomains routed through the tunnel, served by Traefik, and rewritten by AdGuard
  tunnelSubdomains = [
    "vault"
    "pixel"
    "dash"
    "guard"
    "home"
    "tape"
    "dev"
    "creneau"
    "apps"
    "relay"
    "cabas"
    "auth"
    "disk"
    "assets"
  ];
}
