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
    # initExtra = ''
    #   eval "$(starship init zsh)"
    # '';
    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch";
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

