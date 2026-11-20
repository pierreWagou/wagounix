{
  config,
  host,
  pkgs,
  ...
}:

let
  dokployTraefikConfig = pkgs.writeText "dokploy-traefik.yml" ''
    global:
      sendAnonymousUsage: false
    providers:
      file:
        directory: /etc/dokploy/traefik/dynamic
        watch: true
    entryPoints:
      web:
        address: ":80"
    api:
      insecure: false
  '';
in
{
  sops = {
    secrets = {
      dokploy-db-password = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "dokploy-postgres.env" = {
        content = "POSTGRES_PASSWORD=${config.sops.placeholder.dokploy-db-password}\n";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /etc/dokploy 0777 root root -"
    "d /etc/dokploy/traefik 0777 root root -"
    "d /etc/dokploy/traefik/dynamic 0777 root root -"
  ];

  systemd.services.dokploy-deploy = {
    description = "Deploy Dokploy stack via Docker Swarm";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "300";
    };

    path = with pkgs; [
      docker
      coreutils
      gnugrep
    ];

    script = ''
      set -euo pipefail

      ADVERTISE_ADDR="${host.serverIP}"
      DOKPLOY_HOST_PORT="3001"     # Port 3000 is taken by AdGuard web UI (127.0.0.1:3000)
      DOKPLOY_TRAEFIK_HTTP_PORT="9080"
      DOKPLOY_TRAEFIK_HTTPS_PORT="8443"

      # Ensure Docker Swarm is initialized
      if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "Initializing Docker Swarm..."
        docker swarm init --advertise-addr "$ADVERTISE_ADDR"
      else
        echo "Docker Swarm already active."
      fi

      # Ensure dokploy-network overlay exists (Dokploy infra: UI, postgres, redis, traefik)
      if ! docker network ls --filter name=dokploy-network --format '{{.Name}}' | grep -q '^dokploy-network$'; then
        echo "Creating dokploy-network overlay..."
        docker network create --driver overlay --attachable dokploy-network
      fi

      # Ensure apps overlay network exists (isolated network for Dokploy-deployed app containers)
      if ! docker network ls --filter name=apps --format '{{.Name}}' | grep -q '^apps$'; then
        echo "Creating apps overlay network..."
        docker network create --driver overlay --attachable apps
      fi

      # Deploy or update dokploy-postgres service
      DB_PASSWORD=$(cat ${config.sops.secrets.dokploy-db-password.path})
      if docker service ls --filter name=dokploy-postgres --format '{{.Name}}' 2>/dev/null | grep -qx 'dokploy-postgres'; then
        echo "dokploy-postgres already deployed, skipping."
      else
        echo "Deploying dokploy-postgres..."
        docker service create \
          --detach \
          --name dokploy-postgres \
          --constraint 'node.role==manager' \
          --network dokploy-network \
          --env POSTGRES_USER=dokploy \
          --env POSTGRES_DB=dokploy \
          --env POSTGRES_PASSWORD="$DB_PASSWORD" \
          --mount type=volume,source=dokploy-postgres,target=/var/lib/postgresql/data \
          postgres:16
      fi

      # Deploy or update dokploy-redis service
      if docker service ls --filter name=dokploy-redis --format '{{.Name}}' 2>/dev/null | grep -qx 'dokploy-redis'; then
        echo "dokploy-redis already deployed, skipping."
      else
        echo "Deploying dokploy-redis..."
        docker service create \
          --detach \
          --name dokploy-redis \
          --constraint 'node.role==manager' \
          --network dokploy-network \
          --mount type=volume,source=dokploy-redis,target=/data \
          redis:7
      fi

      # Deploy or update dokploy-traefik service
      # Internal router for Dokploy-deployed apps.
      # Published to 127.0.0.1:8080 only — NixOS cloudflared forwards app traffic here.
      # Connected to both dokploy-network (to read dynamic config) and apps (to reach containers).
      # Uses a clean static config (not Dokploy's traefik.yml) to avoid port conflicts.
      # Use docker service ls with grep -qx for exact name match (docker service inspect
      # returns exit code 0 even for non-existent services, making it unreliable).
      if docker service ls --filter name=dokploy-traefik --format '{{.Name}}' 2>/dev/null | grep -qx 'dokploy-traefik'; then
        echo "dokploy-traefik already deployed, skipping."
      else
        echo "Deploying dokploy-traefik..."
        docker service create \
          --detach \
          --name dokploy-traefik \
          --constraint 'node.role==manager' \
          --network dokploy-network \
          --network apps \
          --publish published="$DOKPLOY_TRAEFIK_HTTP_PORT",target=80,protocol=tcp,mode=host \
          --mount type=bind,source=/etc/dokploy/traefik,target=/etc/dokploy/traefik \
          --mount type=bind,source=${dokployTraefikConfig},target=/etc/traefik/traefik.yml,readonly=true \
          traefik:v3.3.5
      fi

      # Deploy or update the main dokploy service
      CURRENT_PORT=$(docker service inspect dokploy --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null || echo "")
      if [ -n "$CURRENT_PORT" ] && [ "$CURRENT_PORT" != "$DOKPLOY_HOST_PORT" ]; then
        echo "Dokploy service exists but uses port $CURRENT_PORT, recreating on port $DOKPLOY_HOST_PORT..."
        docker service rm dokploy
        CURRENT_PORT=""
      fi
      if docker service ls --filter name=dokploy --format '{{.Name}}' 2>/dev/null | grep -qx 'dokploy'; then
        echo "Updating dokploy service to latest..."
        docker service update \
          --detach \
          --image dokploy/dokploy:latest \
          --env-add DATABASE_URL="postgresql://dokploy:$DB_PASSWORD@dokploy-postgres:5432/dokploy" \
          --update-parallelism 1 \
          --update-order stop-first \
          dokploy
      else
        echo "Deploying dokploy service..."
        docker service create \
          --name dokploy \
          --replicas 1 \
          --detach \
          --network dokploy-network \
          --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
          --mount type=bind,source=/etc/dokploy,target=/etc/dokploy \
          --mount type=volume,source=dokploy,target=/root/.docker \
          --publish published="$DOKPLOY_HOST_PORT",target=3000,mode=host \
          --update-parallelism 1 \
          --update-order stop-first \
          --constraint 'node.role == manager' \
          --env ADVERTISE_ADDR="$ADVERTISE_ADDR" \
          --env DATABASE_URL="postgresql://dokploy:$DB_PASSWORD@dokploy-postgres:5432/dokploy" \
          --env TRAEFIK_PORT="$DOKPLOY_TRAEFIK_HTTP_PORT" \
          --env TRAEFIK_SSL_PORT="$DOKPLOY_TRAEFIK_HTTPS_PORT" \
          --env TZ="${host.timezone}" \
          dokploy/dokploy:v0.29.8
      fi

      echo "Dokploy stack deployed. UI available at https://apps.${host.domain}"
    '';
  };
}
