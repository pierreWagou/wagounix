{ pkgs, ... }:

{
  virtualisation = {
    # Podman: container runtime for NixOS-managed services (declarative, via quadlet-nix).
    # dockerCompat is disabled because Docker itself is also enabled (for Dokploy).
    podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Docker: required by Dokploy, which uses Docker Swarm for app deployments.
    # Provides /var/run/docker.sock and docker service create.
    docker = {
      enable = true;
      autoPrune.enable = true;
    };

    # Shared network for all NixOS-managed services — Traefik discovers containers via labels
    quadlet.networks.proxy = { };
  };

  environment.systemPackages = with pkgs; [
    podman-compose # for manual debugging: podman-compose logs, exec, etc.
  ];
}
