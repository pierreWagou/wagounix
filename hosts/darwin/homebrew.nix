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
      "Dashlane/homebrew-tap" = inputs.homebrew-dashlane;
      "vjeantet/homebrew-tap" = inputs.homebrew-alerter;
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
      "alerter"
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
          appdir = host.restrictedAppDir;
        };
      }
      "flutter"
      "ghostty"
      "google-chrome"
      "google-drive"
      "hiddenbar"
      "logitune"
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
          appdir = host.restrictedAppDir;
        };
      }
      "seafile-client"
      "synology-drive"
      "tailscale-app"
      "thunderbird"
      "visual-studio-code"
      "vlc"
      "zen"
      "zoom"
    ];
  };
}
