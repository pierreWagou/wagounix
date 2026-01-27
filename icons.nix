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
        path = "/Applications/Docker.app";
        icon = ./icons/docker.icns;
      }
      {
        path = "/Applications/FileZilla.app";
        icon = ./icons/filezilla.icns;
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
        path = "/Applications/Google Docs.app";
        icon = ./icons/google_docs.icns;
      }
      {
        path = "/Applications/Google Drive.app";
        icon = ./icons/google_drive.icns;
      }
      {
        path = "/Applications/Google Sheets.app";
        icon = ./icons/google_sheets.icns;
      }
      {
        path = "/Applications/Google Slides.app";
        icon = ./icons/google_slides.icns;
      }
      {
        path = "/Applications/Hidden Bar.app";
        icon = ./icons/hidden_bar.icns;
      }
      {
        path = "/Applications/Hue Sync.app";
        icon = ./icons/hue_sync.icns;
      }
      {
        path = "/Applications/iMovie.app";
        icon = ./icons/imovie.icns;
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
        path = "/Applications/Microsoft OneNote.app";
        icon = ./icons/microsoft_onenote.icns;
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
        path = "/Applications/OneDrive.app";
        icon = ./icons/microsoft_onedrive.icns;
      }
      {
        path = "/Applications/Raycast.app";
        icon = ./icons/raycast.icns;
      }
      {
        path = "/Users/I544489/Applications/Spotify.app";
        icon = ./icons/spotify.icns;
      }
      {
        path = "/Applications/Steam.app";
        icon = ./icons/steam.icns;
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