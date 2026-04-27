_: {
  networking.firewall = {
    allowedTCPPorts = [
      22 # SSH
      53 # DNS (AdGuard Home)
      80 # HTTP (Traefik redirect to HTTPS)
      443 # HTTPS (Traefik)
    ];
    allowedUDPPorts = [
      53 # DNS (AdGuard Home)
    ];

    # Allow DNS resolution between Podman containers on custom networks
    interfaces."podman+".allowedUDPPorts = [ 53 ];
  };
}
