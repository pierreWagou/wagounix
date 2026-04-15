{ inputs, ... }:
{

  nix-homebrew = {
    taps = {
      "haiperspace/homebrew-hai" = inputs.homebrew-hai;
    };
  };

  homebrew = {
    brews = [
      "gh"
      "hai"
    ];
    casks = [
      "btp"
      "docker-desktop"
      "drawio"
      "figma"
      "microsoft-azure-storage-explorer"
    ];
    masApps = {
      Xcode = 497799835;
    };
  };
}
