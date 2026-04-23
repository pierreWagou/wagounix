{ host, ... }:
{

  system.defaults.dock.persistent-apps = [
    "/Applications/Thunderbird.app/"
    "/Applications/Zen.app/"
    "/Applications/Visual Studio Code.app/"
    "/Applications/Ghostty.app/"
    "${host.restrictedAppDir}/Spotify.app/"
  ];
}
