{
  config,
  lib,
  pkgs,
  host,
  ...
}:

let
  ws = import ../lib/web-service.nix { inherit config host; };
  yamlFormat = pkgs.formats.yaml { };

  mkRouter = rule: service: {
    rule = "Host(`${rule}`)";
    entrypoints = [ "websecure" ];
    tls = { };
    middlewares = [ "secure-headers" ];
    inherit service;
  };

  appRouters = lib.listToAttrs (
    map (sub: {
      name = sub;
      value = mkRouter "${sub}.${host.domain}" "dokploy-traefik";
    }) host.appTunnelSubdomains
  );

  # File provider first: static routes ready before Docker discovery finds containers.
  dynamicConfig = yamlFormat.generate "traefik-dynamic.yml" {
    http = {
      middlewares = {
        secure-headers = {
          headers = {
            stsSeconds = 63072000;
            stsIncludeSubdomains = true;
            stsPreload = true;
            forceSTSHeader = true;
            contentTypeNosniff = true;
            browserXssFilter = true;
            referrerPolicy = "strict-origin-when-cross-origin";
          };
        };
        authentik-forward-auth = {
          forwardAuth = {
            address = "http://authentik-server:9000/outpost.goauthentik.io/auth/traefik";
            trustForwardHeader = true;
            authResponseHeaders = [
              "X-authentik-username"
              "X-authentik-email"
              "X-authentik-name"
              "X-authentik-groups"
              "X-authentik-uid"
            ];
          };
        };
      };
      routers = {
        ttyd = mkRouter "dev.${host.domain}" "ttyd";
        webhook = mkRouter "relay.${host.domain}" "webhook";
        dokploy = mkRouter "apps.${host.domain}" "dokploy";
        homeassistant = mkRouter "home.${host.domain}" "homeassistant-service";
      }
      // appRouters;
      services = {
        ttyd.loadBalancer.servers = [ { url = "http://${host.serverIP}:${toString host.ports.ttyd}"; } ];
        webhook.loadBalancer.servers = [
          { url = "http://${host.serverIP}:${toString host.ports.webhook}"; }
        ];
        dokploy.loadBalancer.servers = [ { url = "http://${host.serverIP}:3001"; } ];
        dokploy-traefik.loadBalancer.servers = [ { url = "http://host.containers.internal:9080"; } ];
        homeassistant-service.loadBalancer.servers = [ { url = "http://host.containers.internal:8123"; } ];
      };
    };
  };
  traefikSvc = ws.mkWebService {
    name = "traefik";
    exposeViaTraefik = false;
    image = "ghcr.io/traefik/traefik:v3.7.1";
    extraLabels = {
      "traefik.enable" = "true";
    };
    publishPorts = [
      "443:443"
      "80:80"
    ];
    volumes = [
      "/run/podman/podman.sock:/run/podman/podman.sock:ro"
      "/var/lib/traefik/letsencrypt:/letsencrypt"
      "${dynamicConfig}:/etc/traefik/dynamic.yml:ro"
    ];
    environmentFiles = [ config.sops.templates."traefik.env".path ];
    exec = [
      "--global.sendanonymoususage=false"
      "--global.checknewversion=false"
      "--log.level=INFO"
      "--api.dashboard=true"
      "--api.insecure=true"
      "--providers.docker=true"
      "--providers.docker.endpoint=unix:///run/podman/podman.sock"
      "--providers.docker.exposedbydefault=false"
      "--providers.docker.network=proxy"
      "--providers.file.filename=/etc/traefik/dynamic.yml"
      "--entrypoints.web.address=:80"
      "--entrypoints.websecure.address=:443"
      "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      "--entrypoints.websecure.http.tls.certresolver=letsencrypt"
      "--entrypoints.websecure.http.tls.domains[0].main=${host.domain}"
      "--entrypoints.websecure.http.tls.domains[0].sans=*.${host.domain}"
      "--entrypoints.websecure.forwardedHeaders.trustedIPs=173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,172.64.0.0/13,131.0.72.0/22,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
      "--certificatesresolvers.letsencrypt.acme.email=${host.acmeEmail}"
      "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
      "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare"
      "--certificatesresolvers.letsencrypt.acme.dnschallenge.resolvers=1.1.1.1:53,1.0.0.1:53"
    ];
  };
in
{
  sops = {
    templates = {
      "traefik.env" = {
        content = "CF_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-dns-token}\n";
      };
    };
  };

  virtualisation.quadlet.containers.traefik.containerConfig = traefikSvc.containerConfig;
  virtualisation.quadlet.containers.traefik.serviceConfig = traefikSvc.serviceConfig // {
    TimeoutStartSec = "120";
  };

  systemd.tmpfiles.rules = traefikSvc.tmpfilesRules ++ [
    "d /var/lib/traefik/letsencrypt 0755 root root -"
  ];
}
