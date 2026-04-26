{ config, host, ... }:

{
  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:latest";
    ports = [ "127.0.0.1:8222:80" ];
    volumes = [
      "/var/lib/vaultwarden:/data"
    ];
    environment = {
      DOMAIN = "https://vault.${host.domain}";
      SIGNUPS_ALLOWED = "false";
      IP_HEADER = "X-Real-IP";
    };
    environmentFiles = [
      config.sops.templates."vaultwarden.env".path
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden 0755 root root -"
  ];
}
