{
  config,
  pkgs,
  host,
  ...
}:

let
  tunnelId = host.cloudflareTunnelId;
  tunnelTarget = "${tunnelId}.cfargotunnel.com";
  zoneId = host.cloudflareZoneId;

  # Hostnames routed through the tunnel — single source of truth
  tunnelHostnames = [
    "vault.${host.domain}"
    "pixel.${host.domain}"
    "cloud.${host.domain}"
    "home.${host.domain}"
    "guard.${host.domain}"
  ];

  ingressRules = builtins.concatStringsSep "\n" (
    map (hostname: ''
      - hostname: ${hostname}
        service: https://localhost:443
        originRequest:
          originServerName: ${host.domain}
    '') tunnelHostnames
  );

  configFile = pkgs.writeText "cloudflared-config.yml" ''
    tunnel: ${tunnelId}
    credentials-file: ${config.sops.secrets.cloudflare-credentials.path}

    ingress:
    ${ingressRules}  - service: http_status:404
  '';

  # Script to ensure DNS CNAME records exist for all tunnel hostnames
  ensureDnsScript = pkgs.writeShellScript "cloudflare-ensure-dns" ''
    CF_TOKEN=$(cat ${config.sops.secrets.cloudflare-dns-token.path})
    ZONE_ID="${zoneId}"
    TUNNEL_TARGET="${tunnelTarget}"

    for HOSTNAME in ${builtins.concatStringsSep " " tunnelHostnames}; do
      # Check if CNAME already exists
      EXISTS=$(${pkgs.curl}/bin/curl -s \
        -H "Authorization: Bearer $CF_TOKEN" \
        "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=CNAME&name=$HOSTNAME" \
        | ${pkgs.jq}/bin/jq '.result | length')

      if [ "$EXISTS" = "0" ]; then
        echo "Creating CNAME: $HOSTNAME -> $TUNNEL_TARGET"
        ${pkgs.curl}/bin/curl -s -X POST \
          -H "Authorization: Bearer $CF_TOKEN" \
          -H "Content-Type: application/json" \
          "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
          -d "{\"type\":\"CNAME\",\"name\":\"$HOSTNAME\",\"content\":\"$TUNNEL_TARGET\",\"proxied\":true}" \
          | ${pkgs.jq}/bin/jq -r 'if .success then "OK" else .errors[0].message end'
      else
        echo "CNAME exists: $HOSTNAME"
      fi
    done
  '';
in
{
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = { };

  # Cloudflare Tunnel — secure remote access without opening ports
  systemd.services.cloudflared-tunnel = {
    description = "Cloudflare Tunnel";
    after = [
      "network-online.target"
    ];
    wants = [
      "network-online.target"
    ];
    wantedBy = [
      "multi-user.target"
    ];
    restartTriggers = [
      config.sops.secrets.cloudflare-credentials.path
      configFile
    ];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared --config ${configFile} tunnel --no-autoupdate run";
      Restart = "on-failure";
      RestartSec = 5;
      User = "cloudflared";
      Group = "cloudflared";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  # Ensure DNS CNAME records exist for all tunnel hostnames
  systemd.services.cloudflare-dns-sync = {
    description = "Ensure Cloudflare DNS records for tunnel";
    after = [
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [
      "network-online.target"
    ];
    wantedBy = [
      "multi-user.target"
    ];
    restartTriggers = [ ensureDnsScript ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ensureDnsScript;
      RemainAfterExit = true;
    };
  };
}
