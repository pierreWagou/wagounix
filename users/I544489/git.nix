{pkgs, ...}: {

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Pierre Romon";
        email = "pierre.romon@gmail.com";
        signingkey = "B780FECB8A2B46AF";
      };
      gpg = {
        program = "${pkgs.gnupg}";
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
        helper = "/etc/profiles/per-user/I544489/bin/git-credential-manager";
      };
      core = {
        excludeFile = "~/.gitiginore";
      };
      # commit = {
      #   gpgSign = true;
      # };
    };
    includes = [
      {
        contentSuffix = "sap";
        condition = "gitdir:~/Repositories/sap/";
        contents.user = {
          email = "pierre.romon@sap.com";
          signingkey = "B662CC76CE0DF9D3";
        };
      }
    ];
    lfs = {
      enable = true;
    };
  };
}
