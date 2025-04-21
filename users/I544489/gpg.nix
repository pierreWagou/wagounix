{pkgs, ...}: {

  programs.gpg = {
    enable = true;
  };

  service.gpg-agent = {
    enable = true;
    pinentryProgram = "${pkgs.pinentry_mac};
  };
}
