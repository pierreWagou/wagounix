{
  config,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;
  ws = import ../lib/web-service.nix { inherit config host; };
  firecrawlVersion = "2.11.110";
  api = ws.mkWebService {
    name = "firecrawl-api";
    subdomain = "crawl";
    image = "ghcr.io/firecrawl/firecrawl:${firecrawlVersion}";
    port = 3002;
    exec = [
      "node"
      "dist/src/harness.js"
      "--start-docker"
    ];
    env = {
      HOST = "0.0.0.0";
      PORT = "3002";
      ENV = "local";
      LOGGING_LEVEL = "info";
      USE_DB_AUTHENTICATION = "false";
      NUM_WORKERS_PER_QUEUE = "8";
      MAX_CONCURRENT_JOBS = "5";
      BROWSER_POOL_SIZE = "5";
      CRAWL_CONCURRENT_REQUESTS = "10";
      HARNESS_STARTUP_TIMEOUT_MS = "60000";
      REDIS_URL = "redis://firecrawl-redis:6379";
      REDIS_RATE_LIMIT_URL = "redis://firecrawl-redis:6379";
      PLAYWRIGHT_MICROSERVICE_URL = "http://firecrawl-playwright:3000/scrape";
      POSTGRES_HOST = "firecrawl-postgres";
      POSTGRES_PORT = "5432";
      POSTGRES_DB = "firecrawl";
      POSTGRES_USER = "firecrawl";
      SEARXNG_ENDPOINT = "http://firecrawl-searxng:8080";
    };
    environmentFiles = [ config.sops.templates."firecrawl.env".path ];
    extraNetworks = [ networks.firecrawl-internal.ref ];
    unitConfig = {
      Requires = [
        containers.firecrawl-postgres.ref
        containers.firecrawl-rabbitmq.ref
        containers.firecrawl-redis.ref
        containers.firecrawl-playwright.ref
        containers.firecrawl-searxng.ref
      ];
      After = [
        containers.firecrawl-postgres.ref
        containers.firecrawl-rabbitmq.ref
        containers.firecrawl-redis.ref
        containers.firecrawl-playwright.ref
        containers.firecrawl-searxng.ref
      ];
    };
  };
  playwright = ws.mkWebService {
    name = "firecrawl-playwright";
    image = "ghcr.io/firecrawl/playwright-service:latest";
    exposeViaTraefik = false;
    networks = [ networks.firecrawl-internal.ref ];
    env = {
      PORT = "3000";
      MAX_CONCURRENT_PAGES = "10";
    };
    shmSize = "1g";
  };
  redis = ws.mkWebService {
    name = "firecrawl-redis";
    image = "redis:alpine";
    exposeViaTraefik = false;
    networks = [ networks.firecrawl-internal.ref ];
    # Upstream explicitly marks Valkey as untested with Firecrawl — stay on Redis.
    exec = [
      "redis-server"
      "--bind"
      "0.0.0.0"
    ];
  };
  rabbitmq = ws.mkWebService {
    name = "firecrawl-rabbitmq";
    image = "docker.io/rabbitmq:3-management";
    exposeViaTraefik = false;
    networks = [ networks.firecrawl-internal.ref ];
    env = {
      RABBITMQ_DEFAULT_USER = "firecrawl";
    };
    environmentFiles = [ config.sops.templates."firecrawl-rabbitmq.env".path ];
    dataDirs = [ "/var/lib/firecrawl-rabbitmq" ];
    dataDirsMode = "0755 999 999";
  };
  pg = ws.mkPostgres {
    name = "firecrawl-postgres";
    image = "ghcr.io/firecrawl/nuq-postgres:latest";
    db = "firecrawl";
    user = "firecrawl";
    passwordEnvFile = config.sops.templates."firecrawl-postgres.env".path;
    networks = [ networks.firecrawl-internal.ref ];
  };
  searxng = ws.mkWebService {
    name = "firecrawl-searxng";
    image = "docker.io/searxng/searxng:2026.11.9-57ff753ad";
    exposeViaTraefik = false;
    networks = [ networks.firecrawl-internal.ref ];
    env = {
      BASE_URL = "http://firecrawl-searxng:8080/";
    };
  };
in
{
  sops = {
    secrets = {
      firecrawl-postgres-password = {
        sopsFile = ./secrets.yaml;
        mode = "0444";
      };

      firecrawl-rabbitmq-user = {
        sopsFile = ./secrets.yaml;
        mode = "0444";
      };

      firecrawl-rabbitmq-password = {
        sopsFile = ./secrets.yaml;
        mode = "0444";
      };

      firecrawl-bull-auth-key = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "firecrawl-postgres.env" = {
        content = "POSTGRES_PASSWORD=${config.sops.placeholder.firecrawl-postgres-password}\n";
      };

      "firecrawl-rabbitmq.env" = {
        content = "RABBITMQ_DEFAULT_PASS=${config.sops.placeholder.firecrawl-rabbitmq-password}\n";
      };

      "firecrawl.env" = {
        content = builtins.concatStringsSep "\n" [
          "POSTGRES_PASSWORD=${config.sops.placeholder.firecrawl-postgres-password}"
          "NUQ_RABBITMQ_URL=amqp://${config.sops.placeholder.firecrawl-rabbitmq-user}:${config.sops.placeholder.firecrawl-rabbitmq-password}@firecrawl-rabbitmq:5672"
          "BULL_AUTH_KEY=${config.sops.placeholder.firecrawl-bull-auth-key}"
        ];
      };
    };
  };

  # Firecrawl-internal network for API, Playwright, Redis, RabbitMQ,
  # Postgres, and SearXNG traffic (not exposed to Traefik).
  virtualisation.quadlet.networks.firecrawl-internal = { };

  virtualisation.quadlet.containers = {
    firecrawl-api.containerConfig = api.containerConfig;
    firecrawl-api.unitConfig = api.unitConfig;

    firecrawl-playwright.containerConfig = playwright.containerConfig;

    firecrawl-redis.containerConfig = redis.containerConfig;

    firecrawl-rabbitmq.containerConfig = rabbitmq.containerConfig;

    firecrawl-postgres.containerConfig = pg.containerConfig;

    firecrawl-searxng.containerConfig = searxng.containerConfig;
  };

  systemd.tmpfiles.rules = pg.tmpfilesRules ++ rabbitmq.tmpfilesRules;
}
