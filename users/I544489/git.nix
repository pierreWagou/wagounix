{pkgs, ...}: {

  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        name = "Pierre Romon";
        email = "pierre.romon@gmail.com";
        signingkey = "45D3CEC692099E37";
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
      commit = {
        gpgSign = true;
      };
    };
    includes = [
      {
        contentSuffix = "sap";
        condition = "gitdir:~/Repositories/sap/";
        contents.user = {
          email = "pierre.romon@sap.com";
          signingkey = "A797343E0BE26535";
        };
      }
    ];
    lfs = {
      enable = true;
    };
  };
}
