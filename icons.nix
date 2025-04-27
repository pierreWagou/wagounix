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
        path = "/Applications/Arc.app";
        icon = ./icons/arc.icns;
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
        path = "/Applications/Postman.app";
        icon = ./icons/postman.icns;
      }
      {
        path = "/Applications/Spotify.app";
        icon = ./icons/spotify.icns;
      }
      {
        path = "/Applications/Visual Studio Code.app";
        icon = ./icons/vscode.icns;
      }
    ];
  };
}