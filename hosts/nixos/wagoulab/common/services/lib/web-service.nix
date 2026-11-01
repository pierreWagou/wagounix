{ config, host }:

let
  qNetworks = config.virtualisation.quadlet.networks;
in
{
  # Standard container on the proxy network, optionally exposed via Traefik.
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
  #
  # Variants:
  #   exposeViaTraefik = false  → no Traefik labels (traefik itself, game servers)
  #   networks = [ "host" ]     → host networking (satisfactory, home-assistant)
  #   publishPorts / devices / addGroups / dns / exec / shmSize → passthrough
  #   unitConfig / serviceConfig → quadlet systemd options passthrough
  mkWebService =
    {
      name,
      image,
      subdomain ? null,
      port ? null,
      exposeViaTraefik ? true,
      networks ? null,
      extraNetworks ? [ ],
      env ? { },
      volumes ? [ ],
      environmentFiles ? [ ],
      publishPorts ? [ ],
      devices ? [ ],
      addGroups ? [ ],
      addCapabilities ? [ ],
      dns ? [ ],
      exec ? null,
      shmSize ? null,
      healthCmd ? null,
      dataDirs ? [ ],
      dataDirsMode ? "0755 root root",
      extraLabels ? { },
      unitConfig ? { },
      serviceConfig ? { },
    }:
    let
      allNetworks = (if networks == null then [ qNetworks.proxy.ref ] else networks) ++ extraNetworks;
      traefikLabels =
        if exposeViaTraefik then
          (
            assert subdomain != null && port != null;
            {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.rule" = "Host(`${subdomain}.${host.domain}`)";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.middlewares" = "secure-headers@file";
              "traefik.http.services.${name}.loadbalancer.server.port" = toString port;
            }
          )
        else
          { };
    in
    {
      containerConfig = {
        inherit
          image
          volumes
          environmentFiles
          publishPorts
          devices
          addGroups
          addCapabilities
          dns
          ;
        environments = env;
        noNewPrivileges = true;
        networks = allNetworks;
        labels = traefikLabels // extraLabels;
      }
      // (if exec == null then { } else { inherit exec; })
      // (if shmSize == null then { } else { inherit shmSize; })
      // (if healthCmd == null then { } else { inherit healthCmd; });

      tmpfilesRules = map (dir: "d ${dir} ${dataDirsMode} -") dataDirs;

      inherit unitConfig serviceConfig;
    };
}
