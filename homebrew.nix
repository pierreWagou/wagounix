{ inputs, config, lib, pkgs, ... }: {

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "I544489";
    mutableTaps = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "Dashlane/homebrew-taps" = inputs.homebrew-dashlane;
      "teamookla/homebrew-speedtest" = inputs.homebrew-speedtest;
      "hAIperspace/hai" = inputs.homebrew-hai;
      "cline/homebrew-cline" = inputs.homebrew-cline;
    };
  };

  homebrew = {
    enable = true;
    greedyCasks = true;
    onActivation = {
      upgrade = true;
      autoUpdate = false;
      cleanup = "zap";
    };
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
      "Dashlane/homebrew-taps"
      "teamookla/homebrew-speedtest"
      "cline/homebrew-cline"
      {
        name = "hAIperspace/hai";
        clone_target = "https://github.tools.sap/hAIperspace/hai-homebrew.git";
      }
    ];
    brews = [
      # "dashlane-cli"
      "gh"
      # "hai"
      # "speedtest"
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
      "font-jetbrains-mono-nerd-font"
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
      kindle = 302584613;
      "Canal+" = 694580816;
      Xcode = 497799835;
    };
  };
}