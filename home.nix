{pkgs, ...}: {
  ##################################################################################################################
  #
  # All Hearty's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
    ../../home/core.nix
    ../../home/programs
    ../../home/shell
  ];

  programs.git = {
    userName = "Pierre Romon";
    userEmail = "alex.vialar@gmail.com";
  };
}
