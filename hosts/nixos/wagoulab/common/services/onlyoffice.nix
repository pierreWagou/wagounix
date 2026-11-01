{ config, host, ... }:

let
  ws = import ./lib/web-service.nix { inherit config host; };
  svc = ws.mkWebService {
    name = "onlyoffice";
    subdomain = "docs";
    image = "docker.io/onlyoffice/documentserver:9.4";
    port = 80;
    env = {
      JWT_ENABLED = "true";
    };
    volumes = [
      "/var/lib/onlyoffice/logs:/var/log/onlyoffice"
      "/var/lib/onlyoffice/data:/var/www/onlyoffice/Data"
      "/var/lib/onlyoffice/lib:/var/lib/onlyoffice"
      "/var/lib/onlyoffice/db:/var/lib/postgresql"
    ];
    environmentFiles = [ config.sops.templates."onlyoffice.env".path ];
    dataDirs = [
      "/var/lib/onlyoffice"
      "/var/lib/onlyoffice/logs"
      "/var/lib/onlyoffice/data"
      "/var/lib/onlyoffice/lib"
      "/var/lib/onlyoffice/db"
    ];
  };
in
{
  virtualisation.quadlet.containers.onlyoffice.containerConfig = svc.containerConfig;

  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
