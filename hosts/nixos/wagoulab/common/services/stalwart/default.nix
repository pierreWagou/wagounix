{
  config,
  pkgs,
  host,
  ...
}:

let
  ws = import ../lib/web-service.nix { inherit config host; };
  # Store pointer: the only file Stalwart keeps in /etc/stalwart.
  # Everything else (domains, accounts, DKIM keys, settings) lives in
  # RocksDB at /var/lib/stalwart. Kept byte-equivalent to the wizard output.
  configJson = pkgs.writeText "stalwart-config.json" ''{"@type":"RocksDb","path":"/var/lib/stalwart/","blobSize":16834,"bufferSize":134217728,"poolWorkers":null}'';
  svc = ws.mkWebService {
    name = "stalwart";
    subdomain = "mailbox";
    image = "docker.io/stalwartlabs/stalwart:v0.16";
    port = 8080;
    addCapabilities = [ "NET_BIND_SERVICE" ];
    env = {
      STALWART_HOSTNAME = "mail.${host.domain}";
      STALWART_PUBLIC_URL = "https://mailbox.${host.domain}";
    };
    volumes = [
      "/var/lib/stalwart:/var/lib/stalwart"
      "${configJson}:/etc/stalwart/config.json:ro"
      "/var/lib/stalwart-logs:/var/log/stalwart"
    ];
    environmentFiles = [ config.sops.templates."stalwart.env".path ];
    publishPorts = [
      "0.0.0.0:25:25/tcp"
      "0.0.0.0:465:465/tcp"
      "0.0.0.0:587:587/tcp"
      "0.0.0.0:143:143/tcp"
      "0.0.0.0:993:993/tcp"
      "0.0.0.0:4190:4190/tcp"
    ];
    dataDirs = [
      "/var/lib/stalwart"
      "/var/lib/stalwart-logs"
    ];
    dataDirsMode = "0755 2000 2000";
  };
in
{
  sops = {
    secrets = {
      stalwart-admin-password = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };

      mailgun-api-key = {
        sopsFile = ./secrets.yaml;
        mode = "0400";
      };
    };

    templates = {
      "stalwart.env" = {
        content = ''
          STALWART_RECOVERY_ADMIN=admin:${config.sops.placeholder.stalwart-admin-password}
          CF_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-dns-token}
          SMTP_RELAY_HOST=smtp.eu.mailgun.org
          SMTP_RELAY_PORT=587
          SMTP_RELAY_USERNAME=postmaster@wagou.fr
          SMTP_RELAY_PASSWORD=${config.sops.placeholder.mailgun-api-key}
        '';
      };
    };
  };

  virtualisation.quadlet.containers.stalwart.containerConfig = svc.containerConfig;

  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
