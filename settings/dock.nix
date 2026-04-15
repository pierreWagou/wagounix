{ host, ... }:
{

  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    persistent-others = [
      "/Users/${host.username}/Downloads"
    ];
  };
}
