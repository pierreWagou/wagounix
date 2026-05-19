{ pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.12"
  ];

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    ventoy
  ];
}
