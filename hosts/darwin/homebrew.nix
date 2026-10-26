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
      "Dashlane/homebrew-tap" = inputs.homebrew-dashlane;
      "vjeantet/homebrew-tap" = inputs.homebrew-alerter;
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
      "alerter"
      "dashlane-cli"
      "yarn"
    ];
    casks = [
      "aerial"
      "alt-tab"
      "betterDisplay"
      "bruno"
      "claude"
      "comfy"
      "discord"
      "docker-desktop"
      "flutter"
      "ghostty"
      "google-chrome"
      "google-drive"
      "hiddenbar"
      "linear"
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
      "tailscale-app"
      "thunderbird"
      "upscayl"
      "visual-studio-code"
      "vlc"
      "whatsapp"
      "zen"
      "zoom"
    ];
  };
}
