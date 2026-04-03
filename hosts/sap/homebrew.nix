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
      "docker-desktop"
      "microsoft"
      "microsoft-azure-storage-explorer"
    ];
  };
}
