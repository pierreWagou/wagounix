{pkgs, ...}: {

  programs.bat = {
    enable = true;
    config = {
      color = "always";
      style = "numbers";
    };
  };

}

