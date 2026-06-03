{ inputs, ... }:
{

  nix-homebrew = {
    taps = {
      "haiperspace/homebrew-hai" = inputs.homebrew-hai;
    };
  };

  homebrew = {
    brews = [
      "hai"
      "gh"
    ];
    casks = [
      "btp"
      "drawio"
      "figma"
      "microsoft-outlook"
      "microsoft-azure-storage-explorer"
    ];
    masApps = {
      Xcode = 497799835;
    };
  };
}
