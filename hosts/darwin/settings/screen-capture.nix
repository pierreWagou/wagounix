{ host, ... }:
{

  system.defaults.screencapture = {
    disable-shadow = true;
    include-date = true;
    location = "${host.homeDir}/Downloads";
    show-thumbnail = true;
    target = "file";
    type = "png";
  };
}
