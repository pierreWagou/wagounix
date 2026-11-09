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
    gh
    git
    gnupg
    go
    mise
    mprocs
    neovim
    opencode
    openldap
    openssl
    pinentry-curses
    rbw
    ripgrep
    sheldon
    sops
    speedtest-cli
    sshfs
    sshpass
    stalwart-cli
    starship
    swaks
    television
    unzip
    wget
    zip
    zoxide
    zsh
  ];
}
