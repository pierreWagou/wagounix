{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    ventoy
  ];
}
