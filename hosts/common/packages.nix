{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Packages for all machines (including wagoulab)
  environment.systemPackages = with pkgs; [
    age
    ansible
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
    mailpit
    mise
    mprocs
    neovim
    opencode
    openldap
    openssl
    pinentry-curses
    rbw
    ripgrep
    sesh
    sheldon
    sops
    speedtest-cli
    sshfs
    sshpass
    stalwart-cli
    starship
    swaks
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
