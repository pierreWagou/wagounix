{
  config,
  host,
  ...
}:

{
  services.webhook = {
    enable = true;
    port = 9000;
    ip = host.serverIP;
    user = "webhook";
    group = "webhook";
    hooksTemplated = {
      rebuild = ''
        {
          "id": "rebuild",
          "execute-command": "/run/wrappers/bin/sudo",
          "pass-arguments-to-command": [
            { "source": "string", "name": "/run/current-system/sw/bin/systemctl" },
            { "source": "string", "name": "start" },
            { "source": "string", "name": "nixos-upgrade.service" }
          ],
          "trigger-rule": {
            "and": [
              {
                "match": {
                  "type": "payload-hmac-sha256",
                  "secret": "{{ getenv "WEBHOOK_SECRET" }}",
                  "parameter": { "source": "header", "name": "X-Hub-Signature-256" }
                }
              },
              {
                "match": {
                  "type": "value",
                  "value": "refs/heads/main",
                  "parameter": { "source": "payload", "name": "ref" }
                }
              }
            ]
          }
        }
      '';
      renovate = ''
        {
          "id": "renovate",
          "execute-command": "/run/wrappers/bin/sudo",
          "pass-arguments-to-command": [
            { "source": "string", "name": "/run/current-system/sw/bin/systemctl" },
            { "source": "string", "name": "start" },
            { "source": "string", "name": "renovate.service" }
          ],
          "trigger-rule": {
            "match": {
              "type": "payload-hmac-sha256",
              "secret": "{{ getenv "WEBHOOK_SECRET" }}",
              "parameter": { "source": "header", "name": "X-Hub-Signature-256" }
            }
          }
        }
      '';
    };
  };

  # Load HMAC secret from sops at runtime
  systemd.services.webhook.serviceConfig.EnvironmentFile = config.sops.templates."webhook.env".path;

  # Allow webhook user to start specific services
  security.sudo.extraRules = [
    {
      users = [ "webhook" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl start nixos-upgrade.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl start renovate.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
