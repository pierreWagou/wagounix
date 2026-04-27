{ pkgs, host, ... }:

let
  inherit (host) serverIP domain;
  webPort = host.adguardWebPort;

  configFile = pkgs.writeText "AdGuardHome.yaml" (
    builtins.toJSON {
      users = [
        {
          name = "admin";
          # Bcrypt hash inline because AdGuard requires it in the YAML config at build time.
          # The matching plaintext password is in sops (adguard-password) for the homepage widget.
          password = "$2b$10$2RWpdsOdYLc0ba5B/4lEoOvdAytSW5ERQs013M8b2E/TtjwLyqto6";
        }
      ];

      http = {
        address = "0.0.0.0:${toString webPort}";
      };

      dns = {
        bind_hosts = [
          "0.0.0.0"
          "::"
        ];
        port = 53;

        bootstrap_dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];

        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
        ];

        upstream_mode = "load_balance";
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;

        rewrites = map (sub: {
          domain = "${sub}.${domain}";
          answer = serverIP;
          enabled = true;
        }) host.tunnelSubdomains;
      };

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
          name = "Steven Black's Unified Hosts";
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        }
        {
          enabled = true;
          id = 3;
          name = "Malicious URL Blocklist";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt";
        }
      ];
    }
  );
in
{
  virtualisation.oci-containers.containers.adguard = {
    image = "adguard/adguardhome:latest";
    ports = [
      "0.0.0.0:53:53/tcp"
      "0.0.0.0:53:53/udp"
      "127.0.0.1:${toString webPort}:${toString webPort}"
    ];
    volumes = [
      "/var/lib/adguardhome/work:/opt/adguardhome/work"
      "/var/lib/adguardhome/conf:/opt/adguardhome/conf"
      "${configFile}:/opt/adguardhome/conf/AdGuardHome.yaml:ro"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/adguardhome 0755 root root -"
    "d /var/lib/adguardhome/work 0755 root root -"
    "d /var/lib/adguardhome/conf 0755 root root -"
  ];
}
