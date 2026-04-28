{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Minimal set of packages for all machines (including wagoulab)
  environment.systemPackages = with pkgs; [
    age
    bat
    bottom
    cloudflared
    eza
    fd
    fzf
    git
    neovim
    openssl
    ripgrep
    sops
    tailscale
    tmux
    unzip
    wget
    zip
    zsh
  ];
}
