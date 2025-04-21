{pkgs, ...}: {

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    colors = "always";
    git = true;
    icons = "always";
    extraOptions = [
      "--tree"
      "--group-directories-first"
      "--git-ignore"
      "-I '.DS_Store|.localized'"
      "--level=1"
    ];
  };

}

