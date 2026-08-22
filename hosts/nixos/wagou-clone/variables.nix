rec {
  username = "wagou";
  homeDir = "/home/${username}";
  hostname = "wagou-clone";
  domain = "wagou.fr";
  serverIP = "192.168.68.66";
  tailscaleIP = "100.81.107.72";
  networkInterface = "enp1s0";
  lanSubnet = "192.168.68.0/24";
  renderGroupGid = "303";
  timezone = "Europe/Paris";
  acmeEmail = "pierre.romon@gmail.com";
  adminEmail = "pierre.romon@gmail.com";
  cloudflareAccountId = "65b2dca00576549f065820b1cd5c76c9";
  cloudflareTunnelId = "b1054c2d-9146-421d-9beb-4efe75a4b25f";

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
    marieland = 7778;
    marielandReliable = 8889;
  };

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
  ];

  appTunnelSubdomains = [
    "creneau-preview"
    "creneau"
  ];

  dnsOnlySubdomains = [
    "satisfactory"
    "marieland"
    "mail"
  ];
}
