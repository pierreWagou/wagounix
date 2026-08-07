{ host, ... }:

{
  networking.firewall = {
    allowedTCPPorts = [
      22 # SSH
      53 # DNS (AdGuard Home)
      80 # HTTP (Traefik redirect to HTTPS)
      443 # HTTPS (Traefik)
      7777 # Satisfactory server
      7778 # Marieland server
      8200 # SofaBaton hub connect-back
      8060 # SofaBaton Wifi Commands
      8888 # Satisfactory reliable messaging
      8889 # Marieland reliable messaging
      25 # SMTP (Stalwart)
      465 # SMTPS (Stalwart)
      587 # Submission (Stalwart)
      143 # IMAP (Stalwart)
      993 # IMAPS (Stalwart)
      4190 # ManageSieve (Stalwart)
    ];
    allowedUDPPorts = [
      53 # DNS (AdGuard Home)
      7777 # Satisfactory game traffic
      7778 # Marieland game traffic
    ];

    interfaces = {
      # Allow DNS resolution between Podman containers on custom networks
      "podman+".allowedUDPPorts = [ 53 ];
      # Allow Traefik container to reach ttyd and webhook on the host
      "podman+".allowedTCPPorts = [
        8123 # Home Assistant
        host.ports.ttyd
        host.ports.webhook
      ];
      # Allow DNS queries from Tailscale clients (remote ad blocking via AdGuard Home)
      "tailscale0".allowedTCPPorts = [ 53 ];
      "tailscale0".allowedUDPPorts = [ 53 ];
    };
  };
}
