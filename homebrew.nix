{ config, lib, pkgs, ... }:

{
  homebrew.enable = true;
  homebrew.brews = [
    "dashlane-cli"
  ]; 
  homebrew.casks = [
    "aerial"
    "alt-tab"
    "altserver"
    "ankama"
    "arc"
    "bruno"
    "docker"
    "drawio"
    "firefox"
    # "font-jetbrains-mono-nerd-font"
    "ghostty"
    "git-credential-manager"
    "google-chrome"
    "google-drive"
    "hiddenbar"
    "iterm2"
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
    "postman"
    "raycast"
    "rectangle"
    "slack"
    "spotify"
    "steam"
    "synology-drive"
    "visual-studio-code"
    "vlc"
    "zen-browser"
  ];
}
