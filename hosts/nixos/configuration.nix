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
    firewall.enable = true;
  };

  virtualisation.docker.enable = true;

  users.users.${host.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
  };
}
