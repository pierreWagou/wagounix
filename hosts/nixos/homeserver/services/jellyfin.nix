{ pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };

  # Intel hardware transcoding (VAAPI/QSV)
  # The Beelink EQI13 has a 12th/13th gen Intel CPU (Alder Lake / Raptor Lake N-series)
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver # VA-API (iHD) — required for hardware decode/encode
    vpl-gpu-rt # oneVPL (QSV) runtime — required for Quick Sync
    intel-compute-runtime # OpenCL (NEO) — used by tone mapping
  ];

  # Use the modern iHD VA-API driver
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";

  # Grant Jellyfin access to GPU devices
  users.users.jellyfin.extraGroups = [
    "video"
    "render"
  ];
}
