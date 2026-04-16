{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cocoapods
    darwin.trash
    git-credential-manager
    pinentry_mac
    spicetify-cli
    spotify-player
  ];
}
