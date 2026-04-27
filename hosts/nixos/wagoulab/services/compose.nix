{ pkgs, ... }:

let
  composeDir = "/var/lib/wagoulab";
  composeFile = "${composeDir}/docker-compose.yml";
in
{
  # Deploy the compose file and homepage config to the server
  systemd.tmpfiles.rules = [
    "d ${composeDir} 0755 root root -"
    "d ${composeDir}/homepage 0755 root root -"
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
  ];

  # Copy compose file and homepage config from the Nix store to the server
  environment.etc = {
    "wagoulab/docker-compose.yml" = {
      source = ../compose/docker-compose.yml;
      target = "wagoulab/docker-compose.yml";
    };
    "wagoulab/homepage/settings.yaml".source = ../compose/homepage/settings.yaml;
    "wagoulab/homepage/widgets.yaml".source = ../compose/homepage/widgets.yaml;
    "wagoulab/homepage/services.yaml".source = ../compose/homepage/services.yaml;
    "wagoulab/homepage/bookmarks.yaml".source = ../compose/homepage/bookmarks.yaml;
    "wagoulab/homepage/custom.css".source = ../compose/homepage/custom.css;
    "wagoulab/homepage/custom.js".source = ../compose/homepage/custom.js;
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

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = composeDir;

      # Copy compose file from /etc to working directory on each start
      ExecStartPre = "${pkgs.writeShellScript "wagoulab-compose-pre" ''
        cp /etc/wagoulab/docker-compose.yml ${composeFile}

        # Homepage config
        mkdir -p ${composeDir}/homepage
        cp /etc/wagoulab/homepage/* /var/lib/wagoulab/homepage/

        # AdGuard Home config (immutable — regenerated from Nix on each deploy)
        mkdir -p /var/lib/adguardhome/conf
        cp /etc/wagoulab/AdGuardHome.yaml /var/lib/adguardhome/conf/AdGuardHome.yaml

        # Cloudflared tunnel config (routes *.wagou.fr -> traefik:80)
        mkdir -p /var/lib/cloudflared
        cp /etc/wagoulab/cloudflared-config.yml /var/lib/cloudflared/config.yml
      ''}";

      ExecStart = "${pkgs.podman-compose}/bin/podman-compose -f ${composeFile} up -d --remove-orphans";
      ExecStop = "${pkgs.podman-compose}/bin/podman-compose -f ${composeFile} down";
    };
  };
}
