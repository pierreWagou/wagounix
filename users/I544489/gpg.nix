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
      {
        text = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          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
          34s5z0WqIOGM9TI=
          =CRB/
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
