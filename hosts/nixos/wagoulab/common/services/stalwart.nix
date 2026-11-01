{ config, host, ... }:

let
  ws = import ./lib/web-service.nix { inherit config host; };
  svc = ws.mkWebService {
    name = "stalwart";
    subdomain = "mailbox";
    image = "stalwartlabs/stalwart:v0.16";
    port = 8080;
    addCapabilities = [ "NET_BIND_SERVICE" ];
    env = {
      STALWART_HOSTNAME = "mail.${host.domain}";
      STALWART_PUBLIC_URL = "https://mailbox.${host.domain}";
    };
    volumes = [
      "/var/lib/stalwart:/var/lib/stalwart"
      "/var/lib/stalwart-config:/etc/stalwart"
      "/var/lib/stalwart-logs:/var/log/stalwart"
    ];
    environmentFiles = [ config.sops.templates."stalwart.env".path ];
    publishPorts = [
      "0.0.0.0:25:25/tcp"
      "0.0.0.0:465:465/tcp"
      "0.0.0.0:587:587/tcp"
      "0.0.0.0:143:143/tcp"
      "0.0.0.0:993:993/tcp"
      "0.0.0.0:4190:4190/tcp"
    ];
    dataDirs = [
      "/var/lib/stalwart"
      "/var/lib/stalwart-config"
      "/var/lib/stalwart-logs"
    ];
    dataDirsMode = "0755 2000 2000";
  };
in
{
  virtualisation.quadlet.containers.stalwart.containerConfig = svc.containerConfig;

  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
