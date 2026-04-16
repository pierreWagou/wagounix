{ host, ... }:
{

  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    persistent-others = [
      "${host.homeDir}/Downloads"
    ];
  };
}
