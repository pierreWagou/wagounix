_: {
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    mediaLocation = "/var/lib/immich";

    database.enable = true;
    redis.enable = true;

    machine-learning.enable = true;

    settings = {
      server.externalDomain = "https://pixel.wagou.fr";
      newVersionCheck.enabled = false;
    };

    accelerationDevices = [ "/dev/dri/renderD128" ];
  };

  hardware.graphics.enable = true;
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
}
