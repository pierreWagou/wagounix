{pkgs, ...}: {

  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        text = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          mDMEZvqwGxYJKwYBBAHaRw8BAQdACutoMlMzW+vXpBjR2cKmC7lDzPF6uClgOnU6
          bXyyBNO0O1BpZXJyZSBSb21vbiAoUGVyc29uYWwgR2l0SHViIGtleSkgPHBpZXJy
          ZS5yb21vbkBnbWFpbC5jb20+iJMEExYKADsWIQS8OiTlkNbr7mDnh/V3Q8NbIxha
          DQUCZvqwGwIbAwULCQgHAgIiAgYVCgkICwIEFgIDAQIeBwIXgAAKCRB3Q8NbIxha
          DdZBAP9xdhUTsQ/EeWlRT+7E3xiVH4M3U0/MC0PJEDN+lRJv+gD+No3WQyuNRV6J
          0UUbJbIjYMXP+U4O8e1a5rpEnY6n0A+4OARm+rAbEgorBgEEAZdVAQUBAQdAI9R7
          EAhTpU4ppVEsZZ56f/JfZoWhvepxS4nQOODj7z4DAQgHiHgEGBYKACAWIQS8OiTl
          kNbr7mDnh/V3Q8NbIxhaDQUCZvqwGwIbDAAKCRB3Q8NbIxhaDecGAP0dc1CzXO8M
          1jDJ/JFKCwx1vmPIqk3Z/KCzrtfAEyPCuQD+Id8bLsE3PZgK/KHNdVxyYQZw/Vyo
          BlMGAInlU0vx8gA=
          =9gM8
          -----END PGP PUBLIC KEY BLOCK-----
        '';
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
