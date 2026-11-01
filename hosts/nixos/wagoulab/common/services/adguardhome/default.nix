{
  config,
  pkgs,
  host,
  ...
}:

let
  ws = import ../lib/web-service.nix { inherit config host; };
  yamlFormat = pkgs.formats.yaml { };

  # AdGuard config — generated as proper YAML from a Nix attrset.
  # schema_version: 34 prevents the broken migration.
  # bootstrap_dns uses :53 port suffix per the v34 schema.
  # trusted_proxies includes the Podman network ranges so Traefik requests aren't rejected.
  # The admin bcrypt hash is injected at activation via the sops template below
  # (secrets don't exist at build time, so the generated YAML carries a sentinel).
  adguardSeed = yamlFormat.generate "AdGuardHome.yaml" {
    schema_version = 34;
    users = [
      {
        name = "admin";
        # Sentinel swapped for the real bcrypt hash from sops at activation
        # (see seedTemplate below). Never a real secret in the store.
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
      # Disable private reverse DNS — AdGuard runs in a container and has no
      # useful local resolver for PTR queries. Without this, it tries the
      # Podman gateway DNS (10.89.x.1) which times out on every reverse lookup.
      use_private_ptr_resolvers = false;
      local_ptr_upstreams = [ ];
    };
    trusted_proxies = [
      "127.0.0.0/8"
    ]
    ++ host.podmanCIDRs;
    filtering = {
      protection_enabled = true;
      filtering_enabled = true;
      rewrites = map (sub: {
        domain = "${sub}.${host.domain}";
        answer = host.serverIP;
        enabled = true;
      }) (host.serviceTunnelSubdomains ++ host.appTunnelSubdomains ++ host.dnsOnlySubdomains);
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
    image = "adguard/adguardhome:v0.107.76";
    port = 3000;
    # Override Podman's DNS injection — without this, Podman injects the
    # network gateway (10.89.x.1:53) into the container's resolv.conf,
    # and AdGuard tries to use it for reverse DNS lookups, causing 2s
    # timeouts on every PTR query and massive latency.
    dns = [ "127.0.0.1" ];
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
  # Rendered seed: generated YAML with the admin hash injected from sops.
  # Colocated here (not in centralized secrets.nix) next to its consumer.
  # replaceVars runs at build time (no content read at eval, so darwin-side
  # `nix eval` keeps working); sops-nix substitutes the placeholder marker
  # at activation. restartUnits picks up rotations automatically.
  seedTemplate = pkgs.replaceVars adguardSeed {
    ADGUARD_PASSWORD_HASH = config.sops.placeholder.adguard-password-hash;
  };
in
{
  # Service secrets, colocated with the service. Values live in
  # services/adguardhome/secrets.yaml (moved verbatim, not rotated).
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

  # Use the image's default entrypoint and CMD.
  # The seed config is copied by ExecStartPre below.
  virtualisation.quadlet.containers.adguard.containerConfig = svc.containerConfig;

  # Copy the Nix-generated seed config before the container starts.
  # This ensures our declarative config is always the starting point while
  # allowing AdGuard to write runtime changes to the file.
  systemd.services.adguard.serviceConfig.ExecStartPre = [
    "${pkgs.coreutils}/bin/cp ${
      config.sops.templates."AdGuardHome.yaml".path
    } /var/lib/adguardhome/conf/AdGuardHome.yaml"
  ];

  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
