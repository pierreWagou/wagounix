{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Minimal set of packages for all machines (including the homeserver)
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
    tmux
    unzip
    wget
    zip
    zsh
  ];
}
