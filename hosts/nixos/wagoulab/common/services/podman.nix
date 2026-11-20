{ pkgs, ... }:

{
  virtualisation = {
    podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # dockerCompat off: Docker itself is enabled separately for Dokploy.
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
