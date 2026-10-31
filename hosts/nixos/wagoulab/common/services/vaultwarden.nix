{ config, host, ... }:

let
  ws = import ./lib/web-service.nix { inherit config host; };
  svc = ws.mkWebService {
    name = "vaultwarden";
    subdomain = "vault";
    image = "vaultwarden/server:1.37.2";
    port = 80;
    env = {
      DOMAIN = "https://vault.${host.domain}";
      SIGNUPS_ALLOWED = "false";
      IP_HEADER = "X-Real-IP";
    };
    volumes = [
      "/var/lib/vaultwarden:/data"
    ];
    environmentFiles = [ config.sops.templates."vaultwarden.env".path ];
    dataDirs = [ "/var/lib/vaultwarden" ];
  };
in
{
  virtualisation.quadlet.containers.vaultwarden.containerConfig = svc.containerConfig;

  systemd.tmpfiles.rules = svc.tmpfilesRules ++ [
    "d /var/backup/vaultwarden 0755 root root -" # for planned borgbackup/restic service
  ];
}
