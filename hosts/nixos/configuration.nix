{
  config,
  pkgs,
  host,
  ...
}:

{
  programs.zsh.enable = true;
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
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAp8p16DEVrTkM0+e9Ch4nmzIgBky2+DVEGwimxYx/FV wagou@homeserver"
    ];
  };
}
