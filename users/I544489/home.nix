{pkgs, ...}: {
  ##################################################################################################################
  #
  # All Hearty's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
     ../../home/core.nix
  ];

  # home = {
  #   homeDirectory = "/Users/I544489";

  #   # This value determines the Home Manager release that your
  #   # configuration is compatible with. This helps avoid breakage
  #   # when a new Home Manager release introduces backwards
  #   # incompatible changes.
  #   #
  #   # You can update Home Manager without changing this value. See
  #   # the Home Manager release notes for a list of state version
  #   # changes in each release.
  #   stateVersion = "24.11";
  # };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;


  programs.git = {
    userName = "Pierre Romon";
    userEmail = "alex.vialar@gmail.com";
  };
}
