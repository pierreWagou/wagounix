{ inputs, ... }: {

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
      "microsoft-azure-storage-explorer"
    ];
  };
}
