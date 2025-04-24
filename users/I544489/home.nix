{pkgs, ...}: {

  imports = [
    ./bat.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./ghostty.nix
    ./home_manager.nix
    ./starship.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  programs.home-manager.enable = true;

  home = {
    homeDirectory = "/Users/I544489";
    stateVersion = "24.11";
    packages = with pkgs; [
      copier
      databricks-cli
      docker
      fd
      figlet
      fortune
      git-credential-manager
      gnupg
      htop
      mas
      maven
      pinentry_mac
      pipx
      poetry
      pyenv
      qrencode
      R
      ripgrep
      scala
      spark
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
      vscode
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
  };
  
  catppuccin.flavor = "mocha";
  catppuccin.enable = true;

  
}
