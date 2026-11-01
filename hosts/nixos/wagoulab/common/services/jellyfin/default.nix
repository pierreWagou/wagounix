{
  config,
  pkgs,
  host,
  ...
}:

let
  ws = import ../lib/web-service.nix { inherit config host; };
  svc = ws.mkWebService {
    name = "jellyfin";
    subdomain = "tape";
    image = "jellyfin/jellyfin:10.11.10";
    port = 8096;
    healthCmd = "none";
    env = {
      LIBVA_DRIVER_NAME = "iHD";
    };
    volumes = [
      "/var/lib/jellyfin/config:/config"
      "/var/lib/jellyfin/cache:/cache"
    ];
    devices = [ "/dev/dri:/dev/dri" ];
    addGroups = [ host.renderGroupGid ]; # render group GID on NixOS (also in immich.nix)
    dataDirs = [
      "/var/lib/jellyfin"
      "/var/lib/jellyfin/config"
      "/var/lib/jellyfin/cache"
    ];
  };
in
{
  sops = {
    secrets = {
      jellyfin-api-key = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };
  };

  virtualisation.quadlet.containers.jellyfin.containerConfig = svc.containerConfig;

  systemd.tmpfiles.rules = svc.tmpfilesRules;

  # Intel hardware transcoding (VAAPI/QSV)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };
}
