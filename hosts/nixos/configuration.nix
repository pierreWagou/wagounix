{ host, ... }:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system.stateVersion = "25.05";

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  networking = {
    hostName = host.hostname;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  virtualisation.docker.enable = true;

  users.users.${host.username} = {
    isNormalUser = true;
    initialPassword = "changeme";
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAp8p16DEVrTkM0+e9Ch4nmzIgBky2+DVEGwimxYx/FV wagou@homeserver"
    ];
  };
}
