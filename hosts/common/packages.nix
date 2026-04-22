{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    age
    bat
    bottom
    chezmoi
    copier
    delta
    docker
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
    openvpn
    pay-respects
    poetry
    R
    ripgrep
    scala
    sesh
    sheldon
    sops
    ssh-to-age
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
