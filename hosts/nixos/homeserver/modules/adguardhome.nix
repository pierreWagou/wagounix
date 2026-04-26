{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab.adguardhome;

  adguardConfig = pkgs.writeText "AdGuardHome.yaml" (
    builtins.toJSON {
      schema_version = 34;

      http = {
        address = "0.0.0.0:3000";
      };

      inherit (cfg) users;

      dns = {
        bind_hosts = [
          "0.0.0.0"
          "::"
        ];
        port = 53;
        bootstrap_dns = cfg.bootstrapDns;
        upstream_dns = cfg.upstreamDns;
        upstream_mode = "load_balance";
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        inherit (cfg) rewrites;
      };

      inherit (cfg) filters;
    }
  );
in
{
  options.homelab.adguardhome = {
    enable = lib.mkEnableOption "AdGuard Home DNS (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Host port for web UI";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/adguardhome";
      description = "Host path for persistent data";
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Admin users (name + bcrypt password hash)";
    };
    bootstrapDns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      description = "Bootstrap DNS servers";
    };
    upstreamDns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "https://dns.cloudflare.com/dns-query"
        "https://dns.google/dns-query"
      ];
      description = "Upstream DNS servers";
    };
    rewrites = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "DNS rewrite rules";
    };
    filters = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Ad/tracker filter lists";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.adguardhome = {
      image = "adguard/adguardhome:latest";
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "127.0.0.1:${toString cfg.port}:3000"
      ];
      volumes = [
        "${cfg.dataDir}/conf:/opt/adguardhome/conf"
        "${cfg.dataDir}/work:/opt/adguardhome/work"
      ];
    };

    # Copy the Nix-generated config before the container starts (replicates mutableSettings = false).
    # AdGuard needs a writable conf directory because its config migrator rewrites the file on startup.
    system.activationScripts.adguardhome-config = ''
      mkdir -p ${cfg.dataDir}/conf
      cp ${adguardConfig} ${cfg.dataDir}/conf/AdGuardHome.yaml
      chmod 644 ${cfg.dataDir}/conf/AdGuardHome.yaml
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
      "d ${cfg.dataDir}/work 0755 root root -"
    ];
  };
}
