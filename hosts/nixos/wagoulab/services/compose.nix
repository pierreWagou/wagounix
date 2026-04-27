{ pkgs, lib, ... }:

let
  baseDir = "/var/lib/wagoulab";

  # All services managed by podman-compose.
  # Each gets its own compose file, working directory, and systemd unit.
  services = [
    "traefik"
    "cloudflared"
    "vaultwarden"
    "opencloud"
    "jellyfin"
    "home-assistant"
    "homepage"
    "adguard"
    "immich"
  ];

  # Generate a systemd service for one compose stack.
  mkComposeService =
    name:
    {
      extraPreStart ? "",
    }:
    let
      workDir = "${baseDir}/${name}";
      composeFile = "${workDir}/docker-compose.yml";
      after = [
        "network-online.target"
        "podman.socket"
        "wagoulab-network.service"
      ]
      ++ lib.optional (name != "traefik" && name != "adguard") "wagoulab-traefik.service";
    in
    {
      description = "wagoulab: ${name}";
      inherit after;
      wants = [
        "network-online.target"
        "podman.socket"
      ];
      requires = [ "wagoulab-network.service" ];
      wantedBy = [ "multi-user.target" ];

      # Force restart when the compose file changes
      restartTriggers = [
        (builtins.hashFile "sha256" ../compose/${name}/docker-compose.yml)
      ];

      path = [
        pkgs.podman
        pkgs.podman-compose
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = workDir;
        TimeoutStartSec = "5min";
        TimeoutStopSec = "2min";
        KillMode = "none";

        ExecStartPre = pkgs.writeShellScript "wagoulab-${name}-pre" ''
          set -euo pipefail

          # Stop old stack if running
          if [ -f "${composeFile}" ]; then
            podman-compose -f "${composeFile}" down --remove-orphans 2>/dev/null || true
          fi

          # Deploy new compose file
          cp "/etc/wagoulab/${name}/docker-compose.yml" "${composeFile}"

          # Service-specific setup
          ${extraPreStart}
        '';

        ExecStart = pkgs.writeShellScript "wagoulab-${name}-start" ''
          set -euo pipefail
          podman-compose -f "${composeFile}" up -d --remove-orphans
        '';

        ExecStop = pkgs.writeShellScript "wagoulab-${name}-stop" ''
          podman-compose -f "${composeFile}" down --remove-orphans 2>/dev/null || true
        '';
      };
    };
in
{
  # Persistent data directories
  systemd.tmpfiles.rules = [
    "d ${baseDir} 0755 root root -"
    "d ${baseDir}/homepage-logs 0755 root root -"
  ]
  # Per-service working directories (must exist before systemd starts the units)
  ++ (map (name: "d ${baseDir}/${name} 0755 root root -") services)
  ++ [
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

  # Deploy compose files and static configs to /etc/wagoulab/
  environment.etc =
    (lib.listToAttrs (
      map (name: {
        name = "wagoulab/${name}/docker-compose.yml";
        value.source = ../compose/${name}/docker-compose.yml;
      }) services
    ))
    // {
      "wagoulab/traefik-dynamic.yml".source = ../compose/traefik-dynamic.yml;
      "wagoulab/homepage/settings.yaml".source = ../compose/homepage/settings.yaml;
      "wagoulab/homepage/widgets.yaml".source = ../compose/homepage/widgets.yaml;
      "wagoulab/homepage/services.yaml".source = ../compose/homepage/services.yaml;
      "wagoulab/homepage/bookmarks.yaml".source = ../compose/homepage/bookmarks.yaml;
      "wagoulab/homepage/custom.css".source = ../compose/homepage/custom.css;
      "wagoulab/homepage/custom.js".source = ../compose/homepage/custom.js;
      "wagoulab/AdGuardHome.yaml".source = ../compose/AdGuardHome.yaml;
    };

  # Systemd services: shared network + per-service compose units
  systemd.services = {
    # Shared Podman network
    wagoulab-network = {
      description = "wagoulab: shared proxy network";
      after = [ "podman.socket" ];
      wants = [ "podman.socket" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "wagoulab-network-start" ''
          podman network exists proxy || podman network create proxy
        '';
        ExecStop = pkgs.writeShellScript "wagoulab-network-stop" ''
          podman network rm proxy 2>/dev/null || true
        '';
      };
    };
  }
  // lib.listToAttrs (
    map (name: {
      name = "wagoulab-${name}";
      value = mkComposeService name (
        if name == "traefik" then
          {
            extraPreStart = ''
              cp "/etc/wagoulab/traefik-dynamic.yml" "/var/lib/traefik/dynamic.yml"
            '';
          }
        else if name == "cloudflared" then
          {
            extraPreStart = ''
              cp "/etc/wagoulab/cloudflared-config.yml" "/var/lib/cloudflared/config.yml"
            '';
          }
        else if name == "adguard" then
          { }
        else
          { }
      );
    }) services
  );
}
