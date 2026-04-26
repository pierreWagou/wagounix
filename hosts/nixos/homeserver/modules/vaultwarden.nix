{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab.vaultwarden;
in
{
  options.homelab.vaultwarden = {
    enable = lib.mkEnableOption "Vaultwarden password manager (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8222;
      description = "Host port for Vaultwarden";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Full domain name (e.g. vault.wagou.fr)";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/vaultwarden";
      description = "Host path for persistent data";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.vaultwarden = {
      image = "vaultwarden/server:latest";
      ports = [ "127.0.0.1:${toString cfg.port}:80" ];
      volumes = [ "${cfg.dataDir}:/data" ];
      environment = {
        DOMAIN = "https://${cfg.domain}";
        SIGNUPS_ALLOWED = "false";
        IP_HEADER = "X-Real-IP";
      };
      environmentFiles = [
        config.sops.templates."vaultwarden.env".path
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];
  };
}
