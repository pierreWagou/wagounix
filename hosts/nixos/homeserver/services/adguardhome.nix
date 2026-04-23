{ host, ... }:

let
  inherit (host) serverIP domain;
in
{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    host = "127.0.0.1";
    port = 3000;
    openFirewall = false;

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
            domain = "vault.${domain}";
            answer = serverIP;
            enabled = true;
          }
          {
            domain = "pixel.${domain}";
            answer = serverIP;
            enabled = true;
          }
          {
            domain = "cloud.${domain}";
            answer = serverIP;
            enabled = true;
          }
          {
            domain = "home.${domain}";
            answer = serverIP;
            enabled = true;
          }
          {
            inherit domain;
            answer = serverIP;
            enabled = true;
          }
          {
            domain = "guard.${domain}";
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
