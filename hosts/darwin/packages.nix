{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Darwin-specific
    cocoapods
    darwin.trash
    git-credential-manager
    pinentry_mac
    spicetify-cli
    spotify-player

    # Workstation tools (not needed on the homeserver)
    copier
    delta
    ffmpeg
    fnm
    git-lfs
    imagemagick
    lazygit
    maven
    mutt-wizard
    nix-index
    openapi-generator-cli
    openvpn
    pay-respects
    poetry
    qrencode
    R
    scala
    terraform
    tree-sitter
    uv
    vivid
    worktrunk
    yt-dlp
  ];
}
