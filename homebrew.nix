{ inputs, config, lib, pkgs, ... }: {

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "I544489";
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "Dashlane/homebrew-taps" = inputs.homebrew-dashlane;
      "haiperspace/homebrew-hai" = inputs.homebrew-hai;
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
      "hai"
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
      {
        name = "discord";
        args = { appdir = "~/Applications"; };
      }
      "docker-desktop"
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
      "microsoft-auto-update"
      "microsoft-azure-storage-explorer"
      "microsoft-edge"
      "microsoft-excel"
      "microsoft-onenote"
      "microsoft-powerpoint"
      "microsoft-teams"
      "microsoft-word"
      "obsidian"
      "onedrive"
      "openvpn-connect"
      "philips-hue-sync"
      "raycast"
      "rectangle"
      "slack"
      {
        name = "spotify";
        args = { appdir = "~/Applications"; };
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