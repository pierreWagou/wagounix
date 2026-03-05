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
    fzf
    fortune
    gh
    git
    git-credential-manager
    github-copilot-cli
    gnupg
    gopass
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
    spicetify-cli
    spotify-player
    starship
    tmux
    darwin.trash
    tree
    unzip
    uv
    vivid
    wget
    yt-dlp
    zip
    zoxide
    zsh
    zsh-fzf-tab
    zsh-you-should-use
    zsh-autosuggestions
    zsh-completions
    zsh-syntax-highlighting
  ];
}
