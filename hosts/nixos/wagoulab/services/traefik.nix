{
  config,
  lib,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;
  yamlFormat = pkgs.formats.yaml { };

  # Helper to build a standard Traefik router attrset.
  mkRouter = rule: service: {
    rule = "Host(`${rule}`)";
    entrypoints = [ "websecure" ];
    tls = { };
    middlewares = [ "secure-headers" ];
    inherit service;
  };

  # App routers — auto-generated from host.appTunnelSubdomains.
  # Each forwards to Dokploy Traefik at 127.0.0.1:8080.
  appRouters = lib.listToAttrs (
    map (sub: {
      name = sub;
      value = mkRouter "${sub}.${host.domain}" "dokploy-traefik";
    }) host.appTunnelSubdomains
  );

  # Traefik dynamic config — defines the shared HSTS/security headers middleware
  # and static routes for native (non-container) and Dokploy-forwarded services.
  # Loaded via the file provider so it's available immediately on startup
  # (before Traefik discovers any containers via the Docker provider).
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
in
{
  virtualisation.quadlet.containers.traefik = {
    containerConfig = {
      image = "ghcr.io/traefik/traefik:v3.7.1";
      noNewPrivileges = true;
      publishPorts = [
        "443:443"
        "80:80"
      ];
      networks = [ networks.proxy.ref ];
      environmentFiles = [ config.sops.templates."traefik.env".path ];
      volumes = [
        "/run/podman/podman.sock:/run/podman/podman.sock:ro"
        "/var/lib/traefik/letsencrypt:/letsencrypt"
        "${dynamicConfig}:/etc/traefik/dynamic.yml:ro"
      ];
      labels = {
        "traefik.enable" = "true";
      };
      exec = [
        "--global.sendanonymoususage=false"
        "--global.checknewversion=false"
        "--log.level=INFO"
        "--api.dashboard=true"
        "--api.insecure=true"
        # Providers
        "--providers.docker=true"
        "--providers.docker.endpoint=unix:///run/podman/podman.sock"
        "--providers.docker.exposedbydefault=false"
        "--providers.docker.network=proxy"
        "--providers.file.filename=/etc/traefik/dynamic.yml"
        # Entrypoints
        "--entrypoints.web.address=:80"
        "--entrypoints.websecure.address=:443"
        # HTTP -> HTTPS redirect
        "--entrypoints.web.http.redirections.entrypoint.to=websecure"
        "--entrypoints.web.http.redirections.entrypoint.scheme=https"
        "--entrypoints.web.http.redirections.entrypoint.permanent=true"
        # Default TLS with wildcard cert
        "--entrypoints.websecure.http.tls.certresolver=letsencrypt"
        "--entrypoints.websecure.http.tls.domains[0].main=${host.domain}"
        "--entrypoints.websecure.http.tls.domains[0].sans=*.${host.domain}"
        # Trust Cloudflare + internal networks for forwarded headers
        "--entrypoints.websecure.forwardedHeaders.trustedIPs=173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,172.64.0.0/13,131.0.72.0/22,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
        # ACME — Let's Encrypt with Cloudflare DNS-01
        "--certificatesresolvers.letsencrypt.acme.email=${host.acmeEmail}"
        "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge.resolvers=1.1.1.1:53,1.0.0.1:53"
      ];
    };
    serviceConfig.TimeoutStartSec = "120";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/traefik/letsencrypt 0755 root root -"
  ];
}
