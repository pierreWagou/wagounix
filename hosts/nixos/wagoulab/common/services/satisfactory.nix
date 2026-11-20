{ config, host, ... }:

let
  ws = import ./lib/web-service.nix { inherit config host; };
  svc = ws.mkWebService {
    name = "satisfactory";
    exposeViaTraefik = false;
    networks = [ "host" ];
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
