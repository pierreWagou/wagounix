rec {
  username = "wagou";
  homeDir = "/home/${username}";
  hostname = "wagou-prime";
  domain = "wagou.fr";
  serverIP = "192.168.68.66";
  tailscaleIP = "100.97.36.56";
  networkInterface = "enp170s0";
  lanSubnet = "192.168.68.0/24";
  renderGroupGid = "303";
  timezone = "Europe/Paris";
  acmeEmail = "pierre.romon@gmail.com";
  adminEmail = "pierre.romon@gmail.com";
  cloudflareAccountId = "65b2dca00576549f065820b1cd5c76c9";
  cloudflareTunnelId = "ca26559c-2858-4c78-867e-41e3c19edb52";

  latitude = 48.8566;
  longitude = 2.3522;

  valkeyImage = "docker.io/valkey/valkey:9.1.0";

  podmanCIDRs = [
    "10.89.0.0/16"
    "172.16.0.0/12"
  ];

  ports = {
    ttyd = 7681;
    webhook = 9000;
    satisfactory = 7777;
    satisfactoryReliable = 8888;
  };

  # Tunnel ingress + AdGuard rewrite + manual Cloudflare CNAME per entry.
  serviceTunnelSubdomains = [
    "vault"
    "pixel"
    "dash"
    "guard"
    "home"
    "tape"
    "dev"
    "apps"
    "relay"
    "cabas"
    "auth"
    "disk"
    "assets"
    "mailbox"
    "ai"
    "docs"
    "crawl"
  ];

  # As above, additionally forwarded to Dokploy.
  appTunnelSubdomains = [
    "creneau-preview"
    "creneau"
  ];

  # AdGuard rewrite only + router port forwarding; no Traefik/tunnel.
  dnsOnlySubdomains = [
    "satisfactory"
    "mail"
  ];
}
