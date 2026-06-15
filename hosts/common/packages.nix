{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Packages for all machines (including wagoulab)
  environment.systemPackages = with pkgs; [
    age
    bat
    bottom
    chezmoi
    eza
    fd
    fzf
    gcc
    git
    gh
    gnupg
    go
    mise
    mprocs
    neovim
    opencode
    openssl
    pinentry-curses
    rbw
    ripgrep
    sesh
    sheldon
    sops
    starship
    television
    tmux
    tmuxinator
    unzip
    wget
    zip
    zoxide
    zsh
  ];
}
