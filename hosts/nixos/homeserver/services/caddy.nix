{
  config,
  lib,
  host,
  ...
}:

let
  homepageImages = ./homepage-images;

  # HSTS header — tells browsers to always use HTTPS for *.wagou.fr
  hsts = ''header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"'';

  # Redirect /favicon.ico to the custom synthwave sunset SVG
  faviconRedirect = ''
    handle /favicon.ico {
      redir https://${config.homelab.homepage.domain}/bg/favicon.svg permanent
    }
  '';

  # Per-subdomain reverse proxy configuration
  # Ports are referenced from container module options (type-checked, cross-referenceable)
  serviceConfigs = {
    vault = ''
      ${hsts}
      ${faviconRedirect}
      reverse_proxy 127.0.0.1:${toString config.homelab.vaultwarden.port} {
        header_up X-Real-IP {remote_host}
      }
    '';
    pixel = ''
      ${hsts}
      ${faviconRedirect}
      reverse_proxy 127.0.0.1:${toString config.homelab.immich.port}
    '';
    cloud = ''
      ${hsts}
      ${faviconRedirect}
      reverse_proxy 127.0.0.1:${toString config.homelab.opencloud.port} {
        header_up X-Forwarded-Proto https
      }
    '';
    home = ''
      ${hsts}
      ${faviconRedirect}
      reverse_proxy 127.0.0.1:${toString config.homelab.home-assistant.port}
    '';
    dash = ''
      ${hsts}
      handle_path /bg/* {
        file_server
        root * ${homepageImages}
      }
      handle {
        reverse_proxy 127.0.0.1:${toString config.homelab.homepage.port}
      }
    '';
    guard = ''
      ${hsts}
      ${faviconRedirect}
      reverse_proxy 127.0.0.1:${toString config.homelab.adguardhome.port}
    '';
  };
in
assert
  builtins.all (sub: serviceConfigs ? ${sub}) host.tunnelSubdomains
  || throw "caddy.nix: every subdomain in tunnelSubdomains must have a matching key in serviceConfigs";
{
  # Wildcard certificate via Let's Encrypt DNS-01 challenge (Cloudflare)
  security.acme = {
    acceptTerms = true;
    defaults.email = host.acmeEmail;

    certs."${host.domain}" = {
      domain = "*.${host.domain}";
      extraDomainNames = [ host.domain ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.sops.templates."caddy.env".path;
      reloadServices = [ "caddy.service" ];
      inherit (config.services.caddy) group;
    };
  };

  # Grant caddy user access to ACME certs
  users.users.${config.services.caddy.user}.extraGroups = [ "acme" ];

  services.caddy = {
    enable = true;

    virtualHosts = lib.genAttrs (map (sub: "${sub}.${host.domain}") host.tunnelSubdomains) (hostname: {
      useACMEHost = host.domain;
      extraConfig = serviceConfigs.${lib.head (lib.splitString "." hostname)};
    });
  };
}
