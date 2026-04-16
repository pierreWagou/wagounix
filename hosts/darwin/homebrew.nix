{
  inputs,
  config,
  host,
  ...
}:
{

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    inherit (host) enableRosetta;
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
      "yarn"
    ];
    casks = [
      "alt-tab"
      "bruno"
      "claude"
      {
        name = "discord";
        args = {
          appdir = host.restricted_app_dir;
        };
      }
      "flutter"
      "ghostty"
      "google-chrome"
      "google-drive"
      "hiddenbar"
      "microsoft-excel"
      "microsoft-outlook"
      "microsoft-powerpoint"
      "microsoft-teams"
      "microsoft-word"
      "obsidian"
      "onedrive"
      "opencode-desktop"
      "openvpn-connect"
      "philips-hue-sync"
      "raycast"
      {
        name = "spotify";
        args = {
          appdir = host.restricted_app_dir;
        };
      }
      "synology-drive"
      "thunderbird"
      "visual-studio-code"
      "vlc"
      "zen"
      "zoom"
    ];
  };
}
