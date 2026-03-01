{ config, lib, pkgs, ... }:

{

  imports = [
    ./settings/control-center.nix
    ./settings/dock.nix
    ./settings/global-domain.nix
    ./settings/finder.nix
    ./settings/screen-capture.nix
    ./settings/screen-saver.nix
    ./settings/software-update.nix
    ./settings/spaces.nix
    ./settings/trackpad.nix
  ];
  
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 524288000; # 500 MiB
  };
  nix.enable = false;

  catpuccin.enable = true;
  catpuccin.flavor = "mocha";
  
  system.stateVersion = 5;
  system.primaryUser = "I544489";

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  users.users= {
    I544489 = {
      name = "I544489";
      home = "/Users/I544489";
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

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
    htop
    imagemagick
    lazygit
    mas
    maven
    neovim
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
    sops
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
