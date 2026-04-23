{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    age
    bat
    bottom
    chezmoi
    cloudflared
    copier
    delta
    eza
    fd
    ffmpeg
    fnm
    fzf
    gh
    git
    git-lfs
    gnupg
    imagemagick
    lazygit
    maven
    mise
    mprocs
    mutt-wizard
    neovim
    nix-index
    openapi-generator-cli
    openssl
    openvpn
    pay-respects
    poetry
    R
    ripgrep
    scala
    sesh
    sheldon
    sops
    starship
    television
    terraform
    tmux
    tmuxinator
    tree-sitter
    unzip
    uv
    vivid
    wget
    worktrunk
    yt-dlp
    zip
    zoxide
    zsh
  ];
}
