{pkgs, ...}: {

  imports = [
    ../../home/core.nix
    ./git.nix
  ];

  # Let Homeg Manager install and manage itself.
  programs.home-manager.enable = true;
}
