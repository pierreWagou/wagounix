{ pkgs, host, ... }:

let
  port = host.jellyfinPort;
in
{
  virtualisation.oci-containers.containers.jellyfin = {
    image = "jellyfin/jellyfin:latest";
    ports = [ "127.0.0.1:${toString port}:8096" ];
    volumes = [
      "/var/lib/jellyfin/config:/config"
      "/var/lib/jellyfin/cache:/cache"
    ];
    environment = {
      # Use the modern iHD VA-API driver for Intel hardware transcoding
      LIBVA_DRIVER_NAME = "iHD";
    };
    # Intel GPU passthrough for VAAPI/QSV hardware transcoding
    extraOptions = [
      "--device=/dev/dri:/dev/dri"
      "--group-add=render"
    ];
  };

  # Intel hardware transcoding (VAAPI/QSV)
  # The Beelink EQI13 has a 12th/13th gen Intel CPU (Alder Lake / Raptor Lake N-series)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API (iHD) — required for hardware decode/encode
      vpl-gpu-rt # oneVPL (QSV) runtime — required for Quick Sync
      intel-compute-runtime # OpenCL (NEO) — used by tone mapping
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin 0755 root root -"
    "d /var/lib/jellyfin/config 0755 root root -"
    "d /var/lib/jellyfin/cache 0755 root root -"
  ];
}
