{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cloudflared
    cocoapods
    darwin.trash
    ffmpeg
    fnm
    git-credential-manager
    git-lfs
    imagemagick
    lazygit
    manga-tui
    maven
    nix-index
    pay-respects
    pinentry_mac
    poetry
    qrencode
    R
    scala
    sketchybar
    spotify-player
    terraform
    tree-sitter
    uv
    vivid
    worktrunk
    yt-dlp
  ];
}
