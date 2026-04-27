{ pkgs, lib, ... }:

let
  # The wagounix repo is cloned here on the server.
  # Compose files are at ${repoDir}/hosts/nixos/wagoulab/compose/<service>/docker-compose.yml
  repoDir = "/opt/wagounix";
  repoUrl = "https://github.com/pierreWagou/wagounix.git";
  composeBase = "${repoDir}/hosts/nixos/wagoulab/compose";

  # All services managed by podman-compose.
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
    let
      composeFile = "${composeBase}/${name}/docker-compose.yml";
      after = [
        "network-online.target"
        "podman.socket"
        "wagoulab-network.service"
        "wagoulab-repo.service"
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
      requires = [
        "wagoulab-network.service"
        "wagoulab-repo.service"
      ];
      wantedBy = [ "multi-user.target" ];

      # Force restart when the compose file changes (detected during nixos-rebuild)
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
        WorkingDirectory = "${composeBase}/${name}";
        TimeoutStartSec = "5min";
        TimeoutStopSec = "2min";
        KillMode = "none";

        ExecStartPre = pkgs.writeShellScript "wagoulab-${name}-pre" ''
          set -euo pipefail

          # Stop old stack if running
          if [ -f "${composeFile}" ]; then
            podman-compose -f "${composeFile}" down --remove-orphans 2>/dev/null || true
          fi
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
  systemd = {
    # Persistent data directories for containers
    tmpfiles.rules = [
      "d /var/lib/wagoulab 0755 root root -"
      "d /var/lib/wagoulab/homepage-logs 0755 root root -"
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

    services = {
      # Git repo clone — ensures /opt/wagounix exists with the latest compose files
      wagoulab-repo = {
        description = "wagoulab: git repo clone";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.git ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "wagoulab-repo-start" ''
            set -euo pipefail
            if [ ! -d "${repoDir}/.git" ]; then
              git clone --branch docker "${repoUrl}" "${repoDir}"
            else
              git -C "${repoDir}" fetch --all --prune
              git -C "${repoDir}" reset --hard origin/docker
            fi
          '';
        };
      };

      # Auto-pull — pulls latest changes and restarts affected services
      wagoulab-pull = {
        description = "wagoulab: pull latest compose changes";
        after = [ "wagoulab-repo.service" ];
        requires = [ "wagoulab-repo.service" ];
        path = [
          pkgs.git
          pkgs.bash
          pkgs.systemd
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "wagoulab-pull" ''
            set -euo pipefail
            cd "${repoDir}"

            OLD=$(git rev-parse HEAD)
            git fetch --all --prune
            git reset --hard origin/docker
            NEW=$(git rev-parse HEAD)

            if [ "$OLD" = "$NEW" ]; then
              echo "No changes"
              exit 0
            fi

            echo "Updated $OLD -> $NEW"
            CHANGED=$(git diff --name-only "$OLD" "$NEW" -- hosts/nixos/wagoulab/compose/)

            for svc in ${lib.concatStringsSep " " services}; do
              if echo "$CHANGED" | grep -q "compose/$svc/\|compose/AdGuardHome\|compose/traefik-dynamic"; then
                echo "Restarting wagoulab-$svc"
                systemctl restart "wagoulab-$svc" || true
              fi
            done
          '';
        };
      };

      # Shared Podman network — all services connect to this
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
        value = mkComposeService name;
      }) services
    );

    # Auto-pull timer — checks for compose changes every 5 minutes
    timers.wagoulab-pull = {
      description = "wagoulab: periodic compose update check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
        RandomizedDelaySec = "30s";
      };
    };
  };
}
