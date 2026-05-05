{ pkgs, lib, ... }:

{
  environment.systemPackages =
    with pkgs;
    [
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
      mise
      mprocs
      mutt-wizard
      nix-index
      openapi-generator-cli
      openvpn
      pay-respects
      poetry
      qrencode
      R
      scala
      television
      terraform
      tree-sitter
      uv
      vivid
      worktrunk
      yt-dlp
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system != "x86_64-darwin") [
      opencode
    ];
}
