{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;
  ws = import ../lib/web-service.nix { inherit config host; };
  # Pinned by digest: 2.11.x rejects the /v2/search schema fields firecrawl-mcp sends.
  firecrawlImage = "ghcr.io/firecrawl/firecrawl@sha256:305ffea700eca1f50f0875b049206b9202ebee0d8efe3a70cc859cad20d46a1a";
  api = ws.mkWebService {
    name = "firecrawl-api";
    subdomain = "crawl";
    image = firecrawlImage;
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
      # Sized for one search user (Nov 2026): 8 workers held ~4 GB idle.
      NUM_WORKERS_PER_QUEUE = "1";
      MAX_CONCURRENT_JOBS = "1";
      BROWSER_POOL_SIZE = "1";
      CRAWL_CONCURRENT_REQUESTS = "2";
      HARNESS_STARTUP_TIMEOUT_MS = "60000";
      REDIS_URL = "redis://firecrawl-redis:6379";
      REDIS_RATE_LIMIT_URL = "redis://firecrawl-redis:6379";
      PLAYWRIGHT_MICROSERVICE_URL = "http://firecrawl-playwright:3000/scrape";
      POSTGRES_HOST = "firecrawl-postgres";
      POSTGRES_PORT = "5432";
      POSTGRES_DB = "postgres";
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
    serviceConfig = {
      # 2 GB cap stops the 5 GB runaway seen with 8 workers.
      MemoryMax = "2G";
    };
  };
  playwright = ws.mkWebService {
    name = "firecrawl-playwright";
    image = "ghcr.io/firecrawl/playwright-service:latest";
    exposeViaTraefik = false;
    networks = [ networks.firecrawl-internal.ref ];
    env = {
      PORT = "3000";
      MAX_CONCURRENT_PAGES = "2";
    };
    shmSize = "1g";
    serviceConfig = {
      MemoryMax = "1G";
    };
  };
  redis = ws.mkWebService {
    name = "firecrawl-redis";
    image = "docker.io/library/redis:alpine";
    exposeViaTraefik = false;
    networks = [ networks.firecrawl-internal.ref ];
    # Upstream marks Valkey untested with Firecrawl — stay on Redis.
    exec = [
      "redis-server"
      "--bind"
      "0.0.0.0"
      "--maxmemory"
      "256mb"
      "--maxmemory-policy"
      "noeviction"
    ];
    serviceConfig = {
      MemoryMax = "384M";
    };
  };
  # rabbitmq.conf: the RABBITMQ_VM_MEMORY_HIGH_WATERMARK env var is fatal
  # on recent images ("deprecated environment variables detected", Nov 2026
  # crash loop). Relative watermark sits under the 768M cgroup cap so RabbitMQ
  # throttles publishers before the OOM killer fires.
  rabbitmqConf = pkgs.writeText "firecrawl-rabbitmq.conf" ''
    vm_memory_high_watermark.relative = 0.02
  '';
  rabbitmq = ws.mkWebService {
    name = "firecrawl-rabbitmq";
    image = "docker.io/rabbitmq:3-management";
    exposeViaTraefik = false;
    networks = [ networks.firecrawl-internal.ref ];
    env = {
      RABBITMQ_DEFAULT_USER = "firecrawl";
    };
    volumes = [ "${rabbitmqConf}:/etc/rabbitmq/rabbitmq.conf:ro" ];
    environmentFiles = [ config.sops.templates."firecrawl-rabbitmq.env".path ];
    dataDirs = [ "/var/lib/firecrawl-rabbitmq" ];
    dataDirsMode = "0755 999 999";
    serviceConfig = {
      MemoryMax = "768M";
    };
  };
  # DB must be postgres (nuq-postgres hardcodes cron.database_name); renaming requires wiping the volume.
  pg = ws.mkPostgres {
    name = "firecrawl-postgres";
    image = "ghcr.io/firecrawl/nuq-postgres:latest";
    db = "postgres";
    user = "firecrawl";
    passwordEnvFile = config.sops.templates."firecrawl-postgres.env".path;
    networks = [ networks.firecrawl-internal.ref ];
    serviceConfig = {
      MemoryMax = "512M";
      # pg_cron logs full SQL every second (~270k lines/day): drop info-level output.
      LogLevelMax = "notice";
      LogRateLimitIntervalSec = "30s";
      LogRateLimitBurst = 200;
    };
  };
  searxng = ws.mkWebService {
    name = "firecrawl-searxng";
    image = "docker.io/searxng/searxng:2026.11.9-57ff753ad";
    exposeViaTraefik = false;
    networks = [ networks.firecrawl-internal.ref ];
    env = {
      BASE_URL = "http://firecrawl-searxng:8080/";
    };
    serviceConfig = {
      MemoryMax = "512M";
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

  virtualisation.quadlet.networks.firecrawl-internal = { };

  virtualisation.quadlet.containers = {
    firecrawl-api = {
      inherit (api) containerConfig unitConfig serviceConfig;
    };

    firecrawl-playwright = {
      inherit (playwright) containerConfig serviceConfig;
    };

    firecrawl-redis = {
      inherit (redis) containerConfig serviceConfig;
    };

    firecrawl-rabbitmq = {
      inherit (rabbitmq) containerConfig serviceConfig;
    };

    firecrawl-postgres = {
      inherit (pg) containerConfig serviceConfig;
    };

    firecrawl-searxng = {
      inherit (searxng) containerConfig serviceConfig;
    };
  };

  systemd.tmpfiles.rules = pg.tmpfilesRules ++ rabbitmq.tmpfilesRules;
}
