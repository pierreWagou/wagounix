{ config, host, ... }:

let
  ws = import ./lib/web-service.nix { inherit config host; };
  svc = ws.mkWebService {
    name = "satisfactory";
    exposeViaTraefik = false;
    networks = [ "host" ];
    # Pinned below latest: Seafile's own docs reference 8.1.x; 9.4 is
    # baked since May 2026 (Docs 10.x is weeks old). Revisit on upgrade.
    image = "docker.io/wolveix/satisfactory-server:latest";
    healthCmd = "none";
    env = {
      MAXPLAYERS = "8";
      PUID = "1000";
      PGID = "1000";
      STEAMBETA = "false";
      LOAD_LATEST_SAVE = "true";
    };
    volumes = [ "/var/lib/satisfactory:/config" ];
    dataDirs = [ "/var/lib/satisfactory" ];
  };
in
{
  virtualisation.quadlet.containers.satisfactory.containerConfig = svc.containerConfig;

  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
