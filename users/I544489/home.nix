{pkgs, ...}: {

  imports = [
    ./bat.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./ghostty.nix
    ./home_manager.nix
    ./pyenv.nix
    ./spicetify.nix
    ./spotify-player.nix
    ./starship.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  programs.home-manager.enable = true;

  home = {
    homeDirectory = "/Users/I544489";
    stateVersion = "24.11";
    packages = with pkgs; [
      cocoapods
      copier
      databricks-cli
      delta
      docker
      fd
      ffmpeg
      figlet
      # flutter
      fortune
      gh
      git-credential-manager
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
      # spark
      # speedtest-cli
      spicetify-cli
      spotify-player
      starship
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
    shellAliases = {
      ga = "git add .";
      gc = "git commit -m";
      gp = "git push";
      gl = "git push";
      gco = "git checkout";
      gb = "git branch";
      build = "sudo darwin-rebuild switch --flake ~/.config/wagounix#sap";
      vpn = "sudo openvpn --config ~/.openvpn/home.ovpn";
    };
  };
  
  catppuccin.flavor = "mocha";
  catppuccin.enable = true;
  
}
