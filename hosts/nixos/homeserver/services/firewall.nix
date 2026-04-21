_: {
  networking.firewall = {
    allowedTCPPorts = [
      80
      53
    ];
    allowedUDPPorts = [ 53 ];
  };
}
