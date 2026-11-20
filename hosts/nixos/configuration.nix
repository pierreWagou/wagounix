{
  config,
  pkgs,
  host,
  ...
}:

{
  nixpkgs.config.allowInsecurePredicate = _: true;

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system.stateVersion = "25.05";

  time.timeZone = host.timezone;

  i18n.defaultLocale = "en_US.UTF-8";

  networking = {
    hostName = host.hostname;
    firewall.enable = true;
  };

  # Caps from the Nov 2026 incident (journald held 2.2 GB RAM + 4.1 GB disk).
  services.journald.settings.Journal = {
    Storage = "persistent";
    SystemMaxUse = "500M";
    RuntimeMaxUse = "128M";
    SystemMaxFileSize = "50M";
    SystemKeepFree = "2G";
  };

  # The box ships with zero swap; 25% is ~8 GB compressed.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:pierreWagou/wagounix#${host.hostname}";
    flags = [ "--refresh" ];
    dates = "04:00";
    allowReboot = false;
  };

  users.users.root = {
    hashedPasswordFile = config.sops.secrets.root-password-hash.path;
  };

  users.users.${host.username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.wagou-password-hash.path;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7V9q0WZKoODnbbHsHDFXwTE4JDEqmhvmKxWG05JhBp wagou@wagou-mac"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUtk99V3fN1Q5y7RGTB9hS6c9pyhW61vJ0LYLqSmJ2s wagou-clone"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEE+s+ZzqKxYwF5fioU+x1Jp2EadsZzVrNjiL+GPP+5Amu1nbihxl2y44HKedOlURBjZYb3FLpW9sse2W4UrbWk= termius-phone"
    ];
  };
}
