{
  host,
  config,
  pkgs,
  ...
}:

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
          password = "ADGUARD_PASSWORD_PLACEHOLDER";
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

  # Replace password placeholder with bcrypt hash derived from sops secret at runtime
  systemd.services.adguardhome = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    serviceConfig = {
      # preStart needs to read sops secret and run sed/mkpasswd
      ExecStartPre = [
        "+${pkgs.writeShellScript "adguard-inject-password" ''
          HASH=$(${pkgs.mkpasswd}/bin/mkpasswd --method=bcrypt --rounds=10 \
            "$(cat ${config.sops.secrets.adguard-password.path})")
          ${pkgs.gnused}/bin/sed -i "s|ADGUARD_PASSWORD_PLACEHOLDER|$HASH|g" \
            /var/lib/AdGuardHome/AdGuardHome.yaml
        ''}"
      ];
    };
  };
}
