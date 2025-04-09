{pkgs, ...}: {
  ##################################################################################################################
  #
  # All Hearty's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
     ../../home/core.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;


  programs.git = {
    userName = "Pierre Romon";
    userEmail = "alex.vialar@gmail.com";
  };
}
