{ host, ... }:
{

  system.defaults.dock.persistent-apps = [
    "/Applications/Zen.app/"
    "/Applications/Microsoft Outlook.app/"
    "/Applications/Microsoft Teams.app/"
    "/Applications/Visual Studio Code.app/"
    "/Applications/Ghostty.app/"
    "${host.restricted_app_dir}/Spotify.app/"
  ];
}
