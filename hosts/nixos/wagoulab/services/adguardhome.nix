{ pkgs, host, ... }:

let
  inherit (host) serverIP domain;

  # AdGuard Home configuration — deployed to the server and mounted into the compose container.
  # Replicates the immutable (mutableSettings = false) behavior of the native NixOS module.
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

      http.address = "0.0.0.0:3000";

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
  # Deploy AdGuard config to the server — the compose container mounts /var/lib/adguardhome/conf/
  environment.etc."wagoulab/AdGuardHome.yaml".source = configFile;
}
