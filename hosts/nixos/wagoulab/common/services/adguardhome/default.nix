{
  config,
  pkgs,
  host,
  ...
}:

let
  ws = import ../lib/web-service.nix { inherit config host; };
  yamlFormat = pkgs.formats.yaml { };

  adguardSeed = yamlFormat.generate "AdGuardHome.yaml" {
    # Pinned: later versions trigger a broken migration.
    schema_version = 34;
    users = [
      {
        name = "admin";
        # Sentinel swapped for the real sops hash at activation; never a real secret in the store.
        password = "@ADGUARD_PASSWORD_HASH@";
      }
    ];
    http.address = "0.0.0.0:3000";
    dns = {
      bind_hosts = [
        "0.0.0.0"
        "::"
      ];
      port = 5353;
      bootstrap_dns = [
        "1.1.1.1:53"
        "8.8.8.8:53"
      ];
      upstream_dns = [
        "https://dns.cloudflare.com/dns-query"
        "https://dns.google/dns-query"
        "1.1.1.1:53"
        "8.8.8.8:53"
      ];
      upstream_mode = "load_balance";
      use_private_ptr_resolvers = false;
      local_ptr_upstreams = [ ];
      hostsfile_enabled = true;
    };
    trusted_proxies = [
      "127.0.0.0/8"
    ]
    ++ host.podmanCIDRs;
    filtering = {
      protection_enabled = true;
      filtering_enabled = true;
      # prime.wagou.fr has no rewrite here — listing "prime" as a subdomain would shadow it.
      rewrites = map (sub: {
        domain = "${sub}.${host.domain}";
        answer = host.serverIP;
        enabled = true;
      }) (host.serviceTunnelSubdomains ++ host.appTunnelSubdomains ++ host.dnsOnlySubdomains);
    };
    # .lan stays out: resolvers fail AAAA here with NOERROR instead of falling back.
    # Answer NXDOMAIN (not empty NOERROR) so clients fail over.
    user_rules = [
      "||tv.lan^$dnstype=AAAA,$dnsrewrite=NXDOMAIN"
      "||x2hub.lan^$dnstype=AAAA,$dnsrewrite=NXDOMAIN"
      "||dione.lan^$dnstype=AAAA,$dnsrewrite=NXDOMAIN"
    ];
    filters = [
      {
        enabled = true;
        id = 1;
        name = "AdGuard DNS filter";
        url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
      }
      {
        enabled = true;
        id = 2;
        name = "Malicious URL Blocklist";
        url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt";
      }
      {
        enabled = true;
        id = 3;
        name = "OISD Big";
        url = "https://big.oisd.nl";
      }
      {
        enabled = true;
        id = 4;
        name = "Liste FR - French ads";
        url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_16.txt";
      }
    ];
  };
  svc = ws.mkWebService {
    name = "adguard";
    subdomain = "guard";
    image = "docker.io/adguard/adguardhome:v0.107.76";
    port = 3000;
    # Overrides Podman DNS injection, which caused 2s timeouts on every PTR query.
    dns = [ "127.0.0.1" ];
    # IPs mirror Deco DHCP reservations — keep both sides in sync.
    addHosts = [
      "tv.lan:192.168.68.72"
      "x2hub.lan:192.168.68.67"
      "dione.lan:192.168.68.54"
    ];
    volumes = [
      "/var/lib/adguardhome/work:/opt/adguardhome/work"
      "/var/lib/adguardhome/conf:/opt/adguardhome/conf"
    ];
    publishPorts = [
      "${host.serverIP}:53:5353/tcp"
      "${host.serverIP}:53:5353/udp"
      "${host.tailscaleIP}:53:5353/tcp"
      "${host.tailscaleIP}:53:5353/udp"
      "127.0.0.1:53:5353/tcp"
      "127.0.0.1:53:5353/udp"
      "127.0.0.1:3000:3000/tcp"
    ];
    dataDirs = [
      "/var/lib/adguardhome"
      "/var/lib/adguardhome/work"
      "/var/lib/adguardhome/conf"
    ];
  };
  # Runs at build time, keeping darwin-side nix eval working.
  seedTemplate = pkgs.replaceVars adguardSeed {
    ADGUARD_PASSWORD_HASH = config.sops.placeholder.adguard-password-hash;
  };
in
{
  sops = {
    secrets = {
      adguard-password = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };

      adguard-password-hash = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "AdGuardHome.yaml" = {
        file = seedTemplate;
        restartUnits = [ "adguard.service" ];
      };
    };
  };

  networking.nameservers = [
    host.serverIP
    # Fallback for when this container is down.
    "1.1.1.1"
  ];
  networking.dhcpcd.extraConfig = "nohook resolv.conf";

  virtualisation.quadlet.containers.adguard.containerConfig = svc.containerConfig;

  systemd.services.adguard.serviceConfig.ExecStartPre = [
    "${pkgs.coreutils}/bin/cp ${
      config.sops.templates."AdGuardHome.yaml".path
    } /var/lib/adguardhome/conf/AdGuardHome.yaml"
  ];

  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
