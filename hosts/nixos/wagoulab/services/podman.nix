{ pkgs, ... }:

{
  # Podman replaces Docker as the container runtime.
  # Containers are managed declaratively via quadlet-nix.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    podman-compose # for manual debugging: podman-compose logs, exec, etc.
  ];

  # Shared network for all services — Traefik discovers containers via labels
  virtualisation.quadlet.networks.proxy = { };
}
