{ pkgs, ... }:

{
  # Intel hardware transcoding (VAAPI/QSV) for Jellyfin and Immich ML
  # The Beelink EQI13 has a 12th/13th gen Intel CPU (Alder Lake / Raptor Lake N-series)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API (iHD) — required for hardware decode/encode
      vpl-gpu-rt # oneVPL (QSV) runtime — required for Quick Sync
      intel-compute-runtime # OpenCL (NEO) — used by tone mapping
    ];
  };
}
