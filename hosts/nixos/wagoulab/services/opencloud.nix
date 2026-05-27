{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;

  # Custom CSP to allow the browser to connect to Authentik for OIDC
  cspConfig = pkgs.writeText "opencloud-csp.yaml" ''
    directives:
      child-src:
        - 'self'
      connect-src:
        - 'self'
        - blob:
        - https://cipher.${host.domain}/
        - https://raw.githubusercontent.com/opencloud-eu/awesome-apps/
        - https://update.opencloud.eu/
      default-src:
        - 'none'
      font-src:
        - 'self'
      frame-ancestors:
        - 'self'
      frame-src:
        - 'self'
        - blob:
        - https://embed.diagrams.net/
      img-src:
        - 'self'
        - data:
        - blob:
        - https://raw.githubusercontent.com/opencloud-eu/awesome-apps/
      manifest-src:
        - 'self'
      media-src:
        - 'self'
      object-src:
        - 'self'
        - blob:
      script-src:
        - 'self'
        - 'unsafe-inline'
        - 'unsafe-eval'
      style-src:
        - 'self'
        - 'unsafe-inline'
  '';
in
{
  virtualisation.quadlet.containers.opencloud = {
    containerConfig = {
      image = "opencloudeu/opencloud-rolling:6.1.0";
      noNewPrivileges = true;
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/opencloud/config:/etc/opencloud"
        "/var/lib/opencloud/data:/var/lib/opencloud"
        "${cspConfig}:/etc/opencloud/csp.yaml:ro"
      ];
      environments = {
        OC_URL = "https://cloud.${host.domain}";
        # OC_INSECURE: required because OC_URL is HTTPS but the service listens on
        # plain HTTP behind Traefik. Without this, OpenCloud's internal health checks
        # against its own URL would fail TLS verification.
        OC_INSECURE = "true";
        PROXY_TLS = "false";
        PROXY_HTTP_ADDR = "0.0.0.0:9200";

        # External OIDC (Authentik)
        OC_OIDC_ISSUER = "https://cipher.${host.domain}/application/o/opencloud/";
        OC_EXCLUDE_RUN_SERVICES = "idp";
        PROXY_OIDC_REWRITE_WELLKNOWN = "true";
        PROXY_CSP_CONFIG_FILE_LOCATION = "/etc/opencloud/csp.yaml";

        # User provisioning
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        PROXY_USER_OIDC_CLAIM = "preferred_username";
        PROXY_USER_CS3_CLAIM = "username";
        GRAPH_USERNAME_MATCH = "none";

        # Web client
        WEB_OIDC_CLIENT_ID = "web";

        # Role assignment from Authentik groups
        PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
        PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM = "roles";

        # Admin (handled by Authentik, not internal bootstrap)
        OC_ADMIN_USER_ID = "";
      };
      entrypoint = "/bin/sh";
      exec = [
        "-c"
        "opencloud init || true; exec opencloud server"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.opencloud.rule" = "Host(`cloud.${host.domain}`)";
        "traefik.http.routers.opencloud.entrypoints" = "websecure";
        "traefik.http.routers.opencloud.tls" = "true";
        "traefik.http.routers.opencloud.middlewares" = "secure-headers@file";
        "traefik.http.services.opencloud.loadbalancer.server.port" = "9200";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/opencloud 0755 1000 1000 -"
    "d /var/lib/opencloud/config 0755 1000 1000 -"
    "d /var/lib/opencloud/data 0755 1000 1000 -"
  ];
}
