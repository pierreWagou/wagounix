{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  environment.systemPackages = with pkgs; [
    age
    bat
    bottom
    chezmoi
    claude-code
    cocoapods
    copier
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
    imagemagick
    lazygit
    mas
    maven
    mise
    mutt-wizard
    mprocs
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
    television
    terraform
    tmux
    tmuxinator
    darwin.trash
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

