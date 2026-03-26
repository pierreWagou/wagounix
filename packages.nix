{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  environment.systemPackages = with pkgs; [
    age
    bat
    chezmoi
    claude-code
    cocoapods
    copier
    databricks-cli
    delta
    docker
    eza
    fd
    ffmpeg
    figlet
    fnm
    fzf
    gh
    git
    git-credential-manager
    github-copilot-cli
    gnupg
    htop
    imagemagick
    lazygit
    mas
    maven
    mutt-wizard
    # neomutt
    neovim
    nix-index
    ookla-speedtest
    openapi-generator-cli
    openvpn
    pay-respects
    pinentry_mac
    poetry
    qrencode
    R
    ripgrep
    scala
    sesh
    sheldon
    spicetify-cli
    spotify-player
    starship
    terraform
    tmux
    tmuxinator
    darwin.trash
    tree-sitter
    unzip
    uv
    vivid
    wget
    yt-dlp
    zip
    zoxide
    zsh
  ];
}

