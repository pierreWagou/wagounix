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
  };
}
