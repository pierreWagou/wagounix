{ inputs, config, lib, pkgs, ... }: {

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "I544489";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "Dashlane/homebrew-taps" = inputs.homebrew-dashlane;
      "teamookla/homebrew-speedtest" = inputs.homebrew-speedtest;
    };
    mutableTaps = true;
  };

  homebrew = {
    enable = true;
    global.autoUpdate = true;
    greedyCasks = true;
    onActivation = {
      cleanup = "uninstall";
    };
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
      "Dashlane/homebrew-taps"
      "teamookla/homebrew-speedtest"
    ];
    brews = [
      "dashlane-cli"
      "speedtest"
    ];
    casks = [
      "aerial"
      "alt-tab"
      "arc"
      "altserver"
      "ankama"
      "bruno"
      "docker-desktop"
      "drawio"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "google-chrome"
      "google-drive"
      "hiddenbar"
      "jellybeansoup-netflix"
      "local"
      "messenger"
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
      "philips-hue-sync"
      "postman"
      "raycast"
      "rectangle"
      "slack"
      "spotify"
      "steam"
      "synology-drive"
      "thunderbird"
      "upscayl"
      "visual-studio-code"
      "vlc"
      "wordpresscom-studio"
      "zen"
    ];
    # masApps = {
    #   "Amazon Prime Video" = 545519333;
    #   "Dashlane Password Manager" = 517914548;
    #   "Dune: Imperium" = 1575414319;
    #   Finary = 1569413444;
    #   "Hotspot Shield—Meilleur VPN" = 771076721;
    #   kindle = 302584613;
    #   myCANAL = 694580816;
    #   Xcode = 497799835;
    # };
  };
}
