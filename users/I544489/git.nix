{pkgs, ...}: {

  programs.git = {
    userName = "Pierre Romon";
    userEmail = "pierre.romon@gmail.com";
    includes = [
      # {
      #   # path = "~/Repositories/wagou/.gitconfig-wagou";
      #   contentSuffix = "wagou";
      #   condition = "gitdir:~/Repositories/wagou/";
      #   contents.signingkey = {
      #     signingkey = "7743C35B23185A0D";
      #   };
      # }
      {
        contentSuffix = "sap";
        condition = "gitdir:~/Repositories/sap/";
        contents.user = {
          email = "pierre.romon@sap.com";
          signingkey = "237A7DA06D9C7293";
        };
      }
    ];
    extraConfig = {
      user = {
        name = "Pierre Romon";
        email = "pierre.romon@gmail.com";
        signingkey = "7743C35B23185A0D";
      };
      gpg = {
        program = "/opt/homebrew/bin/gpg";
      };
      push = {
        autoSetupRemote = true;
      };
      pull = {
        rebase = false;
      };
      init = {
        defaultBranch = "main";
      };
      credential = {
        helper = "osxke/usr/local/share/gcm-core/git-credential-managerychain";
      };
      core = {
        excludeFile = "~/.gitiginore";
      };
      commit = {
        gpgSign = true;
      };
    };

    enable = true;
  };
}
