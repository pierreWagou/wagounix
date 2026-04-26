rec {
  username = "wagou";
  homeDir = "/home/${username}";
  hostname = "homeserver";
  domain = "wagou.fr";
  serverIP = "192.168.68.65";
  acmeEmail = "pierre.romon@gmail.com";
  cloudflareAccountId = "65b2dca00576549f065820b1cd5c76c9";
  cloudflareTunnelId = "77f1d05e-ce21-4a09-8229-13f173b38525";

  # Subdomains routed through the tunnel, served by Caddy, and rewritten by AdGuard
  tunnelSubdomains = [
    "vault"
    "pixel"
    "cloud"
    "dash"
    "guard"
    "home"
  ];
}
