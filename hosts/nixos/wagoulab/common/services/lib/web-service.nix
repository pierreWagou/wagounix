{ config, host }:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  # Standard web service on the proxy network, exposed via Traefik.
  # Encodes wagoulab opinions: proxy network, noNewPrivileges,
  # secure-headers middleware, websecure entrypoint.
  #
  # Usage:
  #   ws = import ./lib/web-service.nix { inherit config host; };
  #   svc = ws.mkWebService {
  #     name = "vaultwarden";
  #     subdomain = "vault";
  #     image = "vaultwarden/server:1.37.2";
  #     port = 80;
  #     env = { SIGNUPS_ALLOWED = "false"; };
  #     volumes = [ "/var/lib/vaultwarden:/data" ];
  #     environmentFiles = [ config.sops.templates."vaultwarden.env".path ];
  #     dataDirs = [ "/var/lib/vaultwarden" ];
  #   };
  # Then:
  #   virtualisation.quadlet.containers.vaultwarden.containerConfig = svc.containerConfig;
  #   systemd.tmpfiles.rules = svc.tmpfilesRules;
  mkWebService =
    {
      name,
      subdomain,
      image,
      port,
      env ? { },
      volumes ? [ ],
      environmentFiles ? [ ],
      dataDirs ? [ ],
      extraLabels ? { },
      extraNetworks ? [ ],
      healthCmd ? null,
    }:
    {
      containerConfig = {
        inherit image volumes environmentFiles;
        environments = env;
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ] ++ extraNetworks;
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.${name}.rule" = "Host(`${subdomain}.${host.domain}`)";
          "traefik.http.routers.${name}.entrypoints" = "websecure";
          "traefik.http.routers.${name}.tls" = "true";
          "traefik.http.routers.${name}.middlewares" = "secure-headers@file";
          "traefik.http.services.${name}.loadbalancer.server.port" = toString port;
        }
        // extraLabels;
      }
      // (if healthCmd == null then { } else { inherit healthCmd; });

      tmpfilesRules = map (dir: "d ${dir} 0755 root root -") dataDirs;
    };
}
