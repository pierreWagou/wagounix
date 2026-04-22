{ inputs, host, ... }:
{

  imports = [
    inputs.darwin-custom-icons.darwinModules.default
  ];

  environment.customIcons = {
    enable = true;
    icons = [
      {
        path = "/Applications/Bruno.app";
        icon = ./icons/bruno.icns;
      }
      {
        path = "/Applications/Docker.app";
        icon = ./icons/docker.icns;
      }
      {
        path = "/Applications/Docker.app/Contents/MacOS/Docker Desktop.app";
        icon = ./icons/docker.icns;
      }
      {
        path = "/Applications/Ghostty.app";
        icon = ./icons/ghostty.icns;
      }
      {
        path = "/Applications/Microsoft Excel.app";
        icon = ./icons/microsoft_excel.icns;
      }
      {
        path = "/Applications/Microsoft Outlook.app";
        icon = ./icons/microsoft_outlook.icns;
      }
      {
        path = "/Applications/Microsoft PowerPoint.app";
        icon = ./icons/microsoft_powerpoint.icns;
      }
      {
        path = "/Applications/Microsoft Teams.app";
        icon = ./icons/microsoft_teams.icns;
      }
      {
        path = "/Applications/Microsoft Word.app";
        icon = ./icons/microsoft_word.icns;
      }
      {
        path = "/Applications/OneDrive.app";
        icon = ./icons/microsoft_onedrive.icns;
      }
      {
        path = "/Applications/Raycast.app";
        icon = ./icons/raycast.icns;
      }
      {
        path = "${host.restricted_app_dir}/Spotify.app";
        icon = ./icons/spotify.icns;
      }
      {
        path = "/Applications/Thunderbird.app";
        icon = ./icons/thunderbird.icns;
      }
      {
        path = "/Applications/Visual Studio Code.app";
        icon = ./icons/vscode.icns;
      }
      {
        path = "/Applications/VLC.app";
        icon = ./icons/vlc.icns;
      }
      {
        path = "/Applications/Zen.app";
        icon = ./icons/zen.icns;
      }
    ];
  };

}
