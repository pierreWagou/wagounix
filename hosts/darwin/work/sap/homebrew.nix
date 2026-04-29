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
    ];
    casks = [
      "btp"
      "drawio"
      "figma"
      "microsoft-azure-storage-explorer"
    ];
    masApps = {
      Xcode = 497799835;
    };
  };
}
