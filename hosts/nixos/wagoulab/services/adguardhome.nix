{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;
  yamlFormat = pkgs.formats.yaml { };

  # AdGuard config — generated as proper YAML from a Nix attrset.
  # schema_version: 34 prevents the broken migration.
  # bootstrap_dns uses :53 port suffix per the v34 schema.
  # trusted_proxies includes the Podman network ranges so Traefik requests aren't rejected.
  adguardConfig = yamlFormat.generate "AdGuardHome.yaml" {
    schema_version = 34;
    users = [
      {
        name = "admin";
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
        "1.1.1.1:53"
        "8.8.8.8:53"
      ];
      upstream_dns = [
        "https://dns.cloudflare.com/dns-query"
        "https://dns.google/dns-query"
      ];
      upstream_mode = "load_balance";
      # Disable private reverse DNS — AdGuard runs in a container and has no
      # useful local resolver for PTR queries. Without this, it tries the
      # Podman gateway DNS (10.89.x.1) which times out on every reverse lookup.
      use_private_ptr_resolvers = false;
      local_ptr_upstreams = [ ];
    };
    trusted_proxies = [
      "10.89.0.0/16"
      "127.0.0.0/8"
      "172.16.0.0/12"
    ];
    filtering = {
      protection_enabled = true;
      filtering_enabled = true;
      rewrites = map (sub: {
        domain = "${sub}.${host.domain}";
        answer = host.serverIP;
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
  };
in
{
  virtualisation.quadlet.containers.adguard = {
    containerConfig = {
      image = "adguard/adguardhome:latest";
      # Override Podman's DNS injection — without this, Podman injects the
      # network gateway (10.89.x.1:53) into the container's resolv.conf,
      # and AdGuard tries to use it for reverse DNS lookups, causing 2s
      # timeouts on every PTR query and massive latency.
      dns = [ "127.0.0.1" ];
      networks = [ networks.proxy.ref ];
      publishPorts = [
        "${host.serverIP}:53:53/tcp"
        "${host.serverIP}:53:53/udp"
        "127.0.0.1:53:53/tcp"
        "127.0.0.1:53:53/udp"
        "127.0.0.1:3000:3000/tcp"
      ];
      volumes = [
        "/var/lib/adguardhome/work:/opt/adguardhome/work"
        "/var/lib/adguardhome/conf:/opt/adguardhome/conf"
        "${adguardConfig}:/opt/adguardhome/AdGuardHome.seed.yaml:ro"
      ];
      # Copy the seed config on every start, then launch AdGuard.
      # This ensures our config is always the starting point.
      # AdGuard may migrate it (schema upgrades), which is fine — the seed
      # is reapplied on each container restart.
      entrypoint = "/bin/sh";
      exec = [
        "-c"
        "cp /opt/adguardhome/AdGuardHome.seed.yaml /opt/adguardhome/conf/AdGuardHome.yaml && exec /opt/adguardhome/AdGuardHome --no-check-update -c /opt/adguardhome/conf/AdGuardHome.yaml -w /opt/adguardhome/work"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.adguard.rule" = "Host(`guard.${host.domain}`)";
        "traefik.http.routers.adguard.entrypoints" = "websecure";
        "traefik.http.routers.adguard.tls" = "true";
        "traefik.http.routers.adguard.middlewares" = "secure-headers@file";
        "traefik.http.services.adguard.loadbalancer.server.port" = "3000";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/adguardhome 0755 root root -"
    "d /var/lib/adguardhome/work 0755 root root -"
    "d /var/lib/adguardhome/conf 0755 root root -"
  ];
}
