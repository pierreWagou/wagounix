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
    enableRosetta = true;
    user = host.username;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "crmne/homebrew-tap" = inputs.homebrew-spotifast;
    };
  };

  homebrew = {
    enable = true;
    greedyCasks = true;
    onActivation = {
      upgrade = true;
      cleanup = "uninstall";
    };
    taps = builtins.map (name: {
      inherit name;
      trusted = true;
    }) (builtins.attrNames config.nix-homebrew.taps);
    brews = [
      "yarn"
    ];
    casks = [
      "aerial"
      "audacity"
      "betterDisplay"
      "bitwarden"
      "bruno"
      "comfy"
      "discord"
      "docker-desktop"
      "finicky"
      "flutter"
      "google-chrome"
      "google-drive"
      "ledger-wallet"
      "microsoft-teams"
      "obsidian"
      "onedrive"
      "onlyoffice"
      "opencode-desktop"
      "philips-hue-sync"
      "raycast"
      "spotifast"
      "spotify"
      "seafile-client"
      "steam"
      "stirling-pdf"
      "tailscale-app"
      "thunderbird"
      "twine-app"
      "ultimaker-cura"
      "upscayl"
      "visual-studio-code"
      "vlc"
      "vorssaint"
      "whatsapp"
      "zen"
      "zoom"
    ];
    masApps = {
      "Amazon Prime Video" = 545519333;
      "Canal+" = 694580816;
      Xcode = 497799835;
    };
  };
}
