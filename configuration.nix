{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [
    git
    vim
    zsh
  ];

  environment.variables.EDITOR = "vim";
  environment.shells = [ pkgs.zsh ];
  system.stateVersion = 5;

  users.users.I544489 = {
    name = "I544489";
    home = "/Users/I544489";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # programs.zsh = {
  #   enable = true;
  #   # Here you may customize additional options
  #   aliases = {
  #     ll = "ls -lh";
  #     la = "ls -lha";
  #   };
  # };

}
