{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Minimal set of packages for all machines (including wagoulab)
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
    neovim
    openssl
    ripgrep
    sesh
    sheldon
    sops
    starship
    tailscale
    tmux
    tmuxinator
    unzip
    wget
    zip
    zoxide
    zsh
  ];
}
