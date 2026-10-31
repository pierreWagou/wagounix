{ config, host, ... }:

let
  ws = import ./lib/web-service.nix { inherit config host; };
  svc = ws.mkWebService {
    name = "kitchenowl";
    subdomain = "cabas";
    image = "tombursch/kitchenowl:v0.7.8";
    port = 8080;
    env = {
      OPEN_REGISTRATION = "false";
      DISABLE_USERNAME_PASSWORD_LOGIN = "true";
      OIDC_ISSUER = "https://auth.${host.domain}/application/o/kitchen-owl/";
      OIDC_CLIENT_ID = "kitchenowl";
      FRONT_URL = "https://cabas.${host.domain}";
    };
    volumes = [
      "/var/lib/kitchenowl:/data"
    ];
    environmentFiles = [ config.sops.templates."kitchenowl.env".path ];
    dataDirs = [ "/var/lib/kitchenowl" ];
  };
in
{
  virtualisation.quadlet.containers.kitchenowl.containerConfig = svc.containerConfig;

  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
