{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab.homepage;

  settingsFile = pkgs.writeText "homepage-settings.yaml" (builtins.toJSON cfg.settings);
  servicesFile = pkgs.writeText "homepage-services.yaml" (builtins.toJSON cfg.services);
  widgetsFile = pkgs.writeText "homepage-widgets.yaml" (builtins.toJSON cfg.widgets);
  bookmarksFile = pkgs.writeText "homepage-bookmarks.yaml" "[]";
  dockerFile = pkgs.writeText "homepage-docker.yaml" "{}";
  customCss = pkgs.writeText "homepage-custom.css" cfg.customCSS;
  customJs = pkgs.writeText "homepage-custom.js" cfg.customJS;
in
{
  options.homelab.homepage = {
    enable = lib.mkEnableOption "Homepage dashboard (Docker)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8082;
      description = "Host port for Homepage";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Full domain name (e.g. dash.wagou.fr)";
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Homepage settings.yaml content (as Nix attrset)";
    };
    services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Homepage services.yaml content (as Nix list)";
    };
    widgets = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Homepage widgets.yaml content (as Nix list)";
    };
    customCSS = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Custom CSS for Homepage";
    };
    customJS = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Custom JavaScript for Homepage";
    };
    allowedHosts = lib.mkOption {
      type = lib.types.str;
      description = "Comma-separated allowed hostnames";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.homepage = {
      image = "ghcr.io/gethomepage/homepage:latest";
      ports = [ "127.0.0.1:${toString cfg.port}:3000" ];
      volumes = [
        "${settingsFile}:/app/config/settings.yaml:ro"
        "${servicesFile}:/app/config/services.yaml:ro"
        "${widgetsFile}:/app/config/widgets.yaml:ro"
        "${bookmarksFile}:/app/config/bookmarks.yaml:ro"
        "${dockerFile}:/app/config/docker.yaml:ro"
        "${customCss}:/app/config/custom.css:ro"
        "${customJs}:/app/config/custom.js:ro"
      ];
      environment = {
        HOMEPAGE_ALLOWED_HOSTS = cfg.allowedHosts;
      };
      environmentFiles = [
        config.sops.templates."homepage.env".path
      ];
      extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
    };
  };
}
