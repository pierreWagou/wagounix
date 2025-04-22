{pkgs, ...}: {

  imports = [
    ../../home/core.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./ghostty.nix
    ./bat.nix
    ./starship.nix
    ./zoxyde.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    bruno
    bat
    spark
    databricks-cli 
    docker
    eza
    fd
    figlet
    fortune
    fzf
    git-lfs
    gnupg
    htop
    mas
    maven
    pinentry_mac
    pipx
    pyenv
    qrencode
    R
    ripgrep
    scala
    speedtest-cli
    spicetify-cli
    spotify-player
    starship
    thefuck
    tmux
    darwin.trash
    tree
    unzip
    uv
    vivid
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
  
  catppuccin.flavor = "mocha";
  catppuccin.enable = true;
}
