{ config, host, ... }:

let
  ws = import ../lib/web-service.nix { inherit config host; };
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
  sops = {
    secrets = {
      kitchenowl-jwt-secret = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };

      kitchenowl-oidc-client-secret = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "kitchenowl.env" = {
        content = builtins.concatStringsSep "\n" [
          "JWT_SECRET_KEY=${config.sops.placeholder.kitchenowl-jwt-secret}"
          "OIDC_CLIENT_SECRET=${config.sops.placeholder.kitchenowl-oidc-client-secret}"
        ];
      };
    };
  };

  virtualisation.quadlet.containers.kitchenowl.containerConfig = svc.containerConfig;

  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
