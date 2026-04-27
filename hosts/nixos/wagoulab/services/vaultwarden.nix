{ config, host, ... }:

let
  port = host.vaultwardenPort;
in
{
  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:latest";
    ports = [ "127.0.0.1:${toString port}:80" ];
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

  systemd.services.podman-vaultwarden.restartTriggers = [
    config.sops.templates."vaultwarden.env".content
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden 0755 root root -"
    "d /var/backup/vaultwarden 0755 root root -"
  ];
}
