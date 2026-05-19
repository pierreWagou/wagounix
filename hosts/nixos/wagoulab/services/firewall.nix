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

    interfaces = {
      # Allow DNS resolution between Podman containers on custom networks
      "podman+".allowedUDPPorts = [ 53 ];
      # Allow Traefik container to reach ttyd on the host
      "podman+".allowedTCPPorts = [ 7681 ];
      # Allow DNS queries from Tailscale clients (remote ad blocking via AdGuard Home)
      "tailscale0".allowedTCPPorts = [ 53 ];
      "tailscale0".allowedUDPPorts = [ 53 ];
    };
  };
}
