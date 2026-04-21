{
  config,
  pkgs,
  ...
}:

let
  serverIP = "192.168.68.65";
in
{
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  services = {
    # Vaultwarden — self-hosted password manager
    vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      backupDir = "/var/backup/vaultwarden";
      config = {
        DOMAIN = "https://vault.wagou.fr";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        IP_HEADER = "X-Real-IP";
      };
    };

    # Caddy — reverse proxy
    caddy = {
      enable = true;
      virtualHosts."vault.wagou.fr".extraConfig = ''
        tls internal
        reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT} {
          header_up X-Real-IP {remote_host}
        }
      '';
    };

    # AdGuard Home — DNS server + ad blocker
    adguardhome = {
      enable = true;
      mutableSettings = false;
      host = "0.0.0.0";
      port = 3000;
      openFirewall = true;

      settings = {
        dns = {
          bind_hosts = [ "0.0.0.0" ];
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
              domain = "vault.wagou.fr";
              answer = serverIP;
              enabled = true;
            }
            {
              domain = "vault.home.lan";
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
  };

  # Cloudflare Tunnel — secure remote access without opening ports
  # Token is stored at /var/lib/cloudflared/tunnel-token on the server
  systemd.services.cloudflared-tunnel = {
    description = "Cloudflare Tunnel";
    after = [
      "network-online.target"
    ];
    wants = [
      "network-online.target"
    ];
    wantedBy = [
      "multi-user.target"
    ];
    serviceConfig = {
      ExecStart = "/bin/sh -c '${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token $(cat /var/lib/cloudflared/tunnel-token)'";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      443
      53
    ];
    allowedUDPPorts = [ 53 ];
  };
}
