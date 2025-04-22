{pkgs, ...}: {
  programs.zoxyde = {
    enable = true;
    enableZshIntegration = true;
  };
}