{ pkgs, ... }:

let
  composeDir = "/var/lib/wagoulab";
  composeFile = "${composeDir}/docker-compose.yml";
in
{
  # Persistent data directories for containers
  systemd.tmpfiles.rules = [
    "d ${composeDir} 0755 root root -"
    "d ${composeDir}/homepage-logs 0755 root root -"
    "d /var/lib/traefik/letsencrypt 0755 root root -"
    "d /var/lib/vaultwarden 0755 root root -"
    "d /var/lib/opencloud 0755 1000 1000 -"
    "d /var/lib/opencloud/config 0755 1000 1000 -"
    "d /var/lib/opencloud/data 0755 1000 1000 -"
    "d /var/lib/jellyfin 0755 root root -"
    "d /var/lib/jellyfin/config 0755 root root -"
    "d /var/lib/jellyfin/cache 0755 root root -"
    "d /var/lib/home-assistant 0755 root root -"
    "d /var/lib/adguardhome 0755 root root -"
    "d /var/lib/adguardhome/work 0755 root root -"
    "d /var/lib/adguardhome/conf 0755 root root -"
    "d /var/lib/immich 0755 root root -"
    "d /var/lib/immich-ml-cache 0755 root root -"
    "d /var/lib/immich-postgres 0755 root root -"
    "d /var/lib/cloudflared 0755 root root -"
  ];

  # Config files deployed to /etc/wagoulab/ — containers mount them directly (read-only)
  environment.etc = {
    "wagoulab/docker-compose.yml".source = ../compose/docker-compose.yml;
    "wagoulab/homepage/settings.yaml".source = ../compose/homepage/settings.yaml;
    "wagoulab/homepage/widgets.yaml".source = ../compose/homepage/widgets.yaml;
    "wagoulab/homepage/services.yaml".source = ../compose/homepage/services.yaml;
    "wagoulab/homepage/bookmarks.yaml".source = ../compose/homepage/bookmarks.yaml;
    "wagoulab/homepage/custom.css".source = ../compose/homepage/custom.css;
    "wagoulab/homepage/custom.js".source = ../compose/homepage/custom.js;
    "wagoulab/traefik-dynamic.yml".source = ../compose/traefik-dynamic.yml;
  };

  # Systemd service — runs podman-compose on boot
  systemd.services.wagoulab-compose = {
    description = "wagoulab service stack (podman-compose)";
    after = [
      "network-online.target"
      "podman.socket"
      "sops-nix.service"
    ];
    wants = [
      "network-online.target"
      "podman.socket"
    ];
    wantedBy = [ "multi-user.target" ];

    path = [
      pkgs.podman
      pkgs.podman-compose
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = composeDir;
      TimeoutStartSec = "5min";
      TimeoutStopSec = "2min";
      KillMode = "none";

      ExecStartPre = "${pkgs.writeShellScript "wagoulab-compose-pre" ''
        # Clean up any stale containers from previous runs
        ${pkgs.podman}/bin/podman rm -af 2>/dev/null || true
        ${pkgs.podman}/bin/podman pod rm -af 2>/dev/null || true

        # Deploy compose file (the only file that needs copying — containers
        # mount everything else directly from /etc/wagoulab/)
        cp /etc/wagoulab/docker-compose.yml ${composeFile}

        # Deploy cloudflared tunnel config
        cp /etc/wagoulab/cloudflared-config.yml /var/lib/cloudflared/config.yml

        # Deploy traefik dynamic config (middleware definitions)
        cp /etc/wagoulab/traefik-dynamic.yml /var/lib/traefik/dynamic.yml
      ''}";

      ExecStart = "${pkgs.podman-compose}/bin/podman-compose -f ${composeFile} up -d --force-recreate --remove-orphans";
      ExecStop = "${pkgs.podman-compose}/bin/podman-compose -f ${composeFile} down";
    };
  };
}
