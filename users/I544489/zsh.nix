{pkgs, ...}: {

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    completionInit = "autoload -Uz compinit && compinit";
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
    history = {
      extended = true;
      ignoreDups = true;
      share = true;
    };
    syntaxHighlighting = {
        enable = true;
    };
    shellAliases = {
      python = "python3";
      ga = "git add .";

    };
    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      }
      {
        name = "zsh-completions";
        src = "${pkgs.zsh-completions}/share/zsh-completions";
      }
      {
        name = "zsh-syntax-highlighting";
        src = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
      }
      {
        name = "zsh-you-should-use";
        src = "${pkgs.zsh-you-should-use}/share/zsh-you-should-use";
      }
      {
        name = "zsh-autoswitch-virtualenv";
        file = "autoswitch_virtualenv.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "MichaelAquilina";
          repo = "zsh-autoswitch-virtualenv";
          tag = "3.7.1";
          sha256 = "hwg9wDMU2XqJ5FQEwMVVaz0n+xZ8NI82tH9VhLfFRC4=";
        };
      }
    ];
    localVariables = {
      preview_ls_cmd = "eza -a --level=1 --tree --icons --group-directories-first --git-ignore -I '.DS_Store|.localized' --color=always";
    };
    initExtra = ''
      zstyle ':fzf-tab:complete:*' fzf-flags $(echo $FZF_DEFAULT_OPTS)
      zstyle ':fzf-tab:complete:code:*' fzf-preview 'bat $realpath 2>/dev/null ||' $preview_ls_cmd '$realpath'
      zstyle ':fzf-tab:complete:cd:*' fzf-preview $preview_ls_cmd '$realpath'
    '';
  };
}

