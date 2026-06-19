{ host, pkgs, ... }:

# Dokploy: self-hosted PaaS for deploying apps via a web UI.
# It requires Docker Swarm (not Podman) — this file enables Docker alongside Podman
# and deploys Dokploy as a Docker Swarm service managed by a NixOS systemd unit.
#
# Architecture:
#   - Existing infra Traefik (Podman/quadlet): routes NixOS services, including apps.wagou.fr → Dokploy UI
#   - Dokploy's bundled Traefik (Docker): routes apps deployed through Dokploy on ports 8080/8443
#   - Cloudflare tunnel: forwards all traffic to the infra Traefik on 443
#
# Dokploy UI: https://apps.wagou.fr
# Apps deployed by Dokploy use subdomains like *.wagou.fr routed via Cloudflare + infra Traefik.
#
# First-time setup (run once after nixos-rebuild switch):
#   docker swarm init --advertise-addr <server-ip>
#   Then the systemd service below will auto-deploy Dokploy on next run.
{
  # Data directory for Dokploy config and Traefik configuration
  systemd.tmpfiles.rules = [
    "d /etc/dokploy 0777 root root -"
    "d /etc/dokploy/traefik 0777 root root -"
    "d /etc/dokploy/traefik/dynamic 0777 root root -"
  ];

  # One-shot service that deploys (or updates) the Dokploy stack on every nixos-rebuild.
  # Requires Docker daemon and Docker Swarm to already be initialized on the host.
  systemd.services.dokploy-deploy = {
    description = "Deploy Dokploy stack via Docker Swarm";
    # Run after docker.service is up
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    # Run on every boot (not just once) so updates are applied
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Retry a few times in case docker is still initializing
      Restart = "on-failure";
      RestartSec = "5s";
    };

    # Make docker and standard tools available in the script PATH
    path = with pkgs; [
      docker
      coreutils
      gnugrep
    ];

    script = ''
      set -euo pipefail

      ADVERTISE_ADDR="${host.serverIP}"
      DOKPLOY_HOST_PORT="3001"     # Port 3000 is taken by AdGuard web UI (127.0.0.1:3000)
      DOKPLOY_TRAEFIK_HTTP_PORT="8080"
      DOKPLOY_TRAEFIK_HTTPS_PORT="8443"

      # Ensure Docker Swarm is initialized
      if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "Initializing Docker Swarm..."
        docker swarm init --advertise-addr "$ADVERTISE_ADDR"
      else
        echo "Docker Swarm already active."
      fi

      # Ensure dokploy overlay network exists
      if ! docker network ls --filter name=dokploy-network --format '{{.Name}}' | grep -q '^dokploy-network$'; then
        echo "Creating dokploy-network overlay..."
        docker network create --driver overlay --attachable dokploy-network
      fi

      # Deploy or update dokploy-postgres service
      if docker service ls --filter name=dokploy-postgres --format '{{.Name}}' | grep -q '^dokploy-postgres$'; then
        echo "dokploy-postgres already deployed, skipping."
      else
        echo "Deploying dokploy-postgres..."
        docker service create \
          --name dokploy-postgres \
          --constraint 'node.role==manager' \
          --network dokploy-network \
          --env POSTGRES_USER=dokploy \
          --env POSTGRES_DB=dokploy \
          --env POSTGRES_PASSWORD=dokploy \
          --mount type=volume,source=dokploy-postgres,target=/var/lib/postgresql/data \
          postgres:16
      fi

      # Deploy or update dokploy-redis service
      if docker service ls --filter name=dokploy-redis --format '{{.Name}}' | grep -q '^dokploy-redis$'; then
        echo "dokploy-redis already deployed, skipping."
      else
        echo "Deploying dokploy-redis..."
        docker service create \
          --name dokploy-redis \
          --constraint 'node.role==manager' \
          --network dokploy-network \
          --mount type=volume,source=dokploy-redis,target=/data \
          redis:7
      fi

      # Deploy or update the main dokploy service
      CURRENT_PORT=$(docker service inspect dokploy --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null || echo "")
      if [ -n "$CURRENT_PORT" ] && [ "$CURRENT_PORT" != "$DOKPLOY_HOST_PORT" ]; then
        echo "Dokploy service exists but uses port $CURRENT_PORT, recreating on port $DOKPLOY_HOST_PORT..."
        docker service rm dokploy
        CURRENT_PORT=""
      fi
      if docker service ls --filter name=dokploy --format '{{.Name}}' | grep -q '^dokploy$'; then
        echo "Updating dokploy service to latest..."
        docker service update \
          --image dokploy/dokploy:latest \
          --update-parallelism 1 \
          --update-order stop-first \
          dokploy
      else
        echo "Deploying dokploy service..."
        docker service create \
          --name dokploy \
          --replicas 1 \
          --network dokploy-network \
          --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
          --mount type=bind,source=/etc/dokploy,target=/etc/dokploy \
          --mount type=volume,source=dokploy,target=/root/.docker \
          --publish published="$DOKPLOY_HOST_PORT",target=3000,mode=host \
          --update-parallelism 1 \
          --update-order stop-first \
          --constraint 'node.role == manager' \
          --env ADVERTISE_ADDR="$ADVERTISE_ADDR" \
          --env TRAEFIK_PORT="$DOKPLOY_TRAEFIK_HTTP_PORT" \
          --env TRAEFIK_SSL_PORT="$DOKPLOY_TRAEFIK_HTTPS_PORT" \
          --env TZ="${host.timezone}" \
          dokploy/dokploy:latest
      fi

      # Deploy or update dokploy-traefik (app-routing Traefik, not infra Traefik)
      # Runs on non-conflicting ports 8080/8443 since 80/443 are taken by infra Traefik.
      # Only start if Dokploy has already generated its traefik.yml config file.
      if docker ps --filter name=dokploy-traefik --format '{{.Names}}' | grep -q 'dokploy-traefik'; then
        echo "dokploy-traefik already running, skipping."
      elif [ -f /etc/dokploy/traefik/traefik.yml ]; then
        echo "Deploying dokploy-traefik..."
        docker run -d \
          --name dokploy-traefik \
          --restart always \
          -v /etc/dokploy/traefik/traefik.yml:/etc/traefik/traefik.yml \
          -v /etc/dokploy/traefik/dynamic:/etc/dokploy/traefik/dynamic \
          -v /var/run/docker.sock:/var/run/docker.sock:ro \
          -p ${toString 8080}:80/tcp \
          -p ${toString 8443}:443/tcp \
          -p ${toString 8443}:443/udp \
          traefik:v3.6.7
        docker network connect dokploy-network dokploy-traefik
      else
        echo "Skipping dokploy-traefik: /etc/dokploy/traefik/traefik.yml not yet generated by Dokploy."
        echo "It will be started automatically on the next restart of this service after Dokploy generates it."
      fi

      echo "Dokploy stack deployed. UI available at https://apps.${host.domain}"
    '';
  };

  # Open ports 8080/8443 on the LAN interface for Dokploy's app-routing Traefik.
  # Port 3000 (Dokploy UI) is proxied via infra Traefik and does not need to be publicly opened.
  networking.firewall.interfaces."${host.networkInterface}" = {
    allowedTCPPorts = [
      8080 # Dokploy Traefik HTTP
      8443 # Dokploy Traefik HTTPS
    ];
  };
}
