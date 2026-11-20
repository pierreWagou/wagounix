{ host, ... }:

{
  networking.firewall = {
    allowedTCPPorts = [
      22
      53
      80
      443
      7777
      8200
      8060
      1883
      8888
      25
      465
      587
      143
      993
      4190
      389
      636
    ];
    allowedUDPPorts = [
      53
      5353
      8102
      7777
    ];

    interfaces = {
      "podman+".allowedUDPPorts = [ 53 ];
      "podman+".allowedTCPPorts = [
        8123
        host.ports.ttyd
        host.ports.webhook
      ];
      "tailscale0".allowedTCPPorts = [ 53 ];
      "tailscale0".allowedUDPPorts = [ 53 ];
    };
  };
}
