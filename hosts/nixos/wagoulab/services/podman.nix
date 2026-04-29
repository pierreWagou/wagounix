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
  # DNS disabled because aardvark-dns binds port 53 inside container network
  # namespaces, which conflicts with AdGuard Home's own port 53 listener.
  # Cloudflared uses the host IP to reach Traefik instead of DNS name resolution.
  virtualisation.quadlet.networks.proxy = {
    networkConfig = {
      disableDns = true;
    };
  };
}
