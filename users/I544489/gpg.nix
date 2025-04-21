{pkgs, ...}: {

  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        text = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          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
          YBvhSjqV6lf4MhiJS+K4O11SrztKvJI=
          =3dYw
          -----END PGP PUBLIC KEY BLOCK-----
        '';
        trust = "ultimate";
      }
    ];
  };

  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
    pinentryPackage = pkgs.pinentry_mac;
    enableSshSupport = true;
  };
}
