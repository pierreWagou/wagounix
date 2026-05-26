{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet.containers.jellyfin = {
    containerConfig = {
      image = "jellyfin/jellyfin:10.11.10";
      healthCmd = "none";
      networks = [ networks.proxy.ref ];
      volumes = [
        "/var/lib/jellyfin/config:/config"
        "/var/lib/jellyfin/cache:/cache"
      ];
      environments = {
        LIBVA_DRIVER_NAME = "iHD";
      };
      devices = [ "/dev/dri:/dev/dri" ];
      addGroups = [ host.renderGroupGID ]; # render group GID on NixOS (also in immich.nix)
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.jellyfin.rule" = "Host(`tape.${host.domain}`)";
        "traefik.http.routers.jellyfin.entrypoints" = "websecure";
        "traefik.http.routers.jellyfin.tls" = "true";
        "traefik.http.routers.jellyfin.middlewares" = "secure-headers@file";
        "traefik.http.services.jellyfin.loadbalancer.server.port" = "8096";
      };
    };
  };

  # Intel hardware transcoding (VAAPI/QSV)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin 0755 root root -"
    "d /var/lib/jellyfin/config 0755 root root -"
    "d /var/lib/jellyfin/cache 0755 root root -"
  ];
}
