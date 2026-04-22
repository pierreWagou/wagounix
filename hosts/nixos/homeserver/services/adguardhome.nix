{ host, ... }:

let
  inherit (host) serverIP;
in
{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    host = "0.0.0.0";
    port = 3000;
    openFirewall = true;

    settings = {
      users = [
        {
          name = "admin";
          password = "$2b$10$2RWpdsOdYLc0ba5B/4lEoOvdAytSW5ERQs013M8b2E/TtjwLyqto6";
        }
      ];

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

        rewrites = [
          {
            domain = "vault.home.lan";
            answer = serverIP;
            enabled = true;
          }
          {
            domain = "pixel.home.lan";
            answer = serverIP;
            enabled = true;
          }
          {
            domain = "cloud.home.lan";
            answer = serverIP;
            enabled = true;
          }
          {
            domain = "home.home.lan";
            answer = serverIP;
            enabled = true;
          }
        ];
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
    };
  };
}
