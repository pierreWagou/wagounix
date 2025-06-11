{ inputs, ... }: {

  imports = [
    inputs.darwin-custom-icons.darwinModules.default
  ];

  environment.customIcons = {
    enable = true;
    icons = [
      {
        path = "/Applications/AltServer.app";
        icon = ./icons/altserver.icns;
      }
      {
        path = "/Applications/AltTab.app";
        icon = ./icons/alttab.icns;
      }
      {
        path = "/Applications/Bruno.app";
        icon = ./icons/bruno.icns;
      }
      {
        path = "/Applications/Ghostty.app";
        icon = ./icons/ghostty.icns;
      }
      {
        path = "/Applications/Google Chrome.app";
        icon = ./icons/google_chrome.icns;
      }
      {
        path = "/Applications/Obsidian.app";
        icon = ./icons/obsidian.icns;
      }
      {
        path = "/Applications/Messenger.app";
        icon = ./icons/messenger.icns;
      }
      {
        path = "/Applications/Microsoft Edge.app";
        icon = ./icons/microsoft_edge.icns;
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
        path = "/Applications/Netflix.app";
        icon = ./icons/netflix.icns;
      }
      {
        path = "/Applications/Raycast.app";
        icon = ./icons/raycast.icns;
      }
      {
        path = "/Applications/Spotify.app";
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
    ];
  };
}