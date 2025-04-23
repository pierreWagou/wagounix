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

  homebrew.enable = true;
  homebrew.brews = [
    "dashlane-cli"
  ]; 
  homebrew.casks = [
    "aerial"
    # "alt-tab"
    "altserver"
    "ankama"
    # "arc"
    # "bruno"
    "docker"
    # "drawio"
    # "font-jetbrains-mono-nerd-font"
    "ghostty"
    # "git-credential-manager"
    # "google-chrome"
    "google-drive"
    # "hiddenbar"
    "jellybeansoup-netflix"
    "messenger"
    "microsoft-auto-update"
    "microsoft-edge"
    "microsoft-excel"
    "microsoft-onenote"
    "microsoft-powerpoint"
    "microsoft-teams"
    "microsoft-word"
    "onedrive"
    "philips-hue-sync"
    # "postman"
    # "raycast"
    # "rectangle"
    "slack"
    # "spotify"
    "steam"
    # "synology-drive"
    # "visual-studio-code"
    "vlc"
    "zen-browser"
  ];
}
