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
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    # onActivation.cleanup = "zap";
    brews = [
      "dashlane-cli"
    ];
    casks = [
      "aerial"
      "alt-tab"
      "arc"
      "altserver"
      "ankama"
      "bruno"
      "docker"
      "drawio"
      # "font-jetbrains-mono-nerd-font"
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
      "upscayl"
      "visual-studio-code"
      "vlc"
      "wordpresscom"
      "wordpresscom-studio"
      "zen-browser"
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
