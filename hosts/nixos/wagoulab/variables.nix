rec {
  username = "wagou";
  homeDir = "/home/${username}";
  hostname = "wagoulab";
  domain = "wagou.fr";
  serverIP = "192.168.68.65";
  tailscaleIP = "100.68.157.70";
  networkInterface = "enp170s0";
  lanSubnet = "192.168.68.0/24";
  renderGroupGID = "303";
  timezone = "Europe/Paris";
  acmeEmail = "pierre.romon@gmail.com";
  cloudflareAccountId = "65b2dca00576549f065820b1cd5c76c9";
  cloudflareTunnelId = "77f1d05e-ce21-4a09-8229-13f173b38525";

  # Subdomains routed through the tunnel, served by Traefik, and rewritten by AdGuard
  tunnelSubdomains = [
    "vault"
    "pixel"
    "cloud"
    "dash"
    "guard"
    "home"
    "tape"
    "dev"
    "creneau"
    "relay"
    "cabas"
  ];
}
