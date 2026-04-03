{ inputs, config, host, ... }: {

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = host.enableRosetta;
    user = host.username;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "Dashlane/homebrew-taps" = inputs.homebrew-dashlane;
    };
  };

  homebrew = {
    enable = true;
    greedyCasks = true;
    onActivation = {
      upgrade = true;
      cleanup = "uninstall";
    };
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "dashlane-cli"
      "gh"
      "yarn"
    ];
    casks = [
      "aerial"
      "alt-tab"
      "altserver"
      "android-studio"
      "arc"
      "AltServer"
      "ankama"
      "bruno"
      "claude"
      {
        name = "discord";
        args = { appdir = host.restricted_app_dir; };
      }
      "drawio"
      "figma"
      "flutter"
      "ghostty"
      "google-chrome"
      "google-drive"
      "hiddenbar"
      "jellybeansoup-netflix"
      "ledger-wallet"
      "local"
      "microsoft-edge"
      "microsoft-excel"
      "microsoft-outlook"
      "microsoft-powerpoint"
      "microsoft-teams"
      "microsoft-word"
      "obsidian"
      "onedrive"
      "openvpn-connect"
      "philips-hue-sync"
      "raycast"
      "slack"
      {
        name = "spotify";
        args = { appdir = host.restricted_app_dir; };
      }
      "steam"
      "synology-drive"
      "thunderbird"
      "twine-app"
      "ultimaker-cura"
      "upscayl"
      "visual-studio-code"
      "vlc"
      "wordpresscom-studio"
      "zen"
      "zoom"
    ];
    masApps = {
      "Amazon Prime Video" = 545519333;
      "Dashlane Password Manager" = 517914548;
      "Hotspot Shield—Meilleur VPN" = 771076721;
      # kindle = 302584613;
      "Canal+" = 694580816;
      Xcode = 497799835;
    };
  };
}
