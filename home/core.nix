{ pkgs, ... }: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    homeDirectory = "/Users/I544489";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
