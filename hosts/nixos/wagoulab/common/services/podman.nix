{ pkgs, ... }:

{
  virtualisation = {
    podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    docker = {
      enable = true;
      autoPrune.enable = true;
    };

    quadlet.networks.proxy = { };
  };

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
