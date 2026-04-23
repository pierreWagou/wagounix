{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Darwin-specific
    cocoapods
    darwin.trash
    git-credential-manager
    opencode
    pinentry_mac
    spicetify-cli
    spotify-player

    # Workstation tools (not needed on the homeserver)
    chezmoi
    copier
    delta
    ffmpeg
    fnm
    gh
    git-lfs
    gnupg
    imagemagick
    lazygit
    maven
    mise
    mprocs
    mutt-wizard
    nix-index
    openapi-generator-cli
    openvpn
    pay-respects
    poetry
    R
    scala
    sesh
    sheldon
    starship
    television
    terraform
    tmuxinator
    tree-sitter
    uv
    vivid
    worktrunk
    yt-dlp
    zoxide
  ];
}
