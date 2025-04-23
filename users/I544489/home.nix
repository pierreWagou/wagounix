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
      alt-tab-macos
      arc-browser
      bruno
      copier
      databricks-cli
      docker
      drawio
      fd
      figlet
      fortune
      git-credential-manager
      gnupg
      google-chrome
      hidden-bar
      htop
      mas
      maven
      netflix
      pinentry_mac
      pipx
      poetry
      postman
      pyenv
      qrencode
      R
      raycast
      rectangle
      ripgrep
      scala
      slack
      spark
      speedtest-cli
      spicetify-cli
      spotify
      spotify-player
      synology-drive-client
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
