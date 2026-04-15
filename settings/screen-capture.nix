{ host, ... }:
{

  system.defaults.screencapture = {
    disable-shadow = true;
    include-date = true;
    location = "/Users/${host.username}/Downloads";
    show-thumbnail = true;
    target = "file";
    type = "png";
  };
}
