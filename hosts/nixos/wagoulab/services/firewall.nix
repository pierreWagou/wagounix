_: {
  networking.firewall = {
    allowedTCPPorts = [
      22
      53
      443
    ];
    allowedUDPPorts = [
      53
    ];

    # Allow DNS resolution between Podman containers on custom networks
    interfaces."podman+".allowedUDPPorts = [ 53 ];
  };
}
