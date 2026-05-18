{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Packages for all machines (including wagoulab)
  environment.systemPackages = with pkgs; [
    age
    bat
    bottom
    chezmoi
    cloudflared
    eza
    fd
    fzf
    git
    gh
    gnupg
    mise
    mprocs
    neovim
    opencode
    openssl
    pinentry-curses
    ripgrep
    sesh
    sheldon
    sops
    starship
    tailscale
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
