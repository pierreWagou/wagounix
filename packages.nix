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
    fortune
    figlet
    fnm
    fzf
    gh
    git
    git-credential-manager
    github-copilot-cli
    gnupg
    gopass
    gum
    htop
    imagemagick
    lazygit
    mas
    maven
    mutt-wizard
    neomutt
    neovim
    ookla-speedtest
    openapi-generator-cli
    openvpn
    pay-respects
    pinentry_mac
    pipx
    poetry
    pyenv
    qrencode
    R
    ripgrep
    scala
    sesh
    sheldon
    spicetify-cli
    spotify-player
    starship
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
