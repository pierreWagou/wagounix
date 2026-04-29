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

  # Shared network for all services — Traefik discovers containers via labels.
  # DNS disabled to prevent aardvark-dns from binding port 53 inside container
  # namespaces, which conflicts with AdGuard Home's DNS listener.
  # Container name resolution is not needed: cloudflared uses the host IP to
  # reach Traefik, and all other inter-container routing goes through Traefik.
  virtualisation.quadlet.networks.proxy = {
    networkConfig = {
      disableDns = true;
    };
  };
}
