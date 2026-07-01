{
  config,
  pkgs,
  ...
}:

let
  # Script that generates a short-lived GitHub App installation token.
  # 1. Builds a JWT (RS256) from the App ID and private key PEM
  # 2. Exchanges the JWT for an installation access token via GitHub API
  # 3. Writes the token to /run/renovate/token
  generate-renovate-token = pkgs.writeShellApplication {
    name = "generate-renovate-token";
    runtimeInputs = [
      pkgs.openssl
      pkgs.curl
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      APP_ID=$(cat "${config.sops.secrets.renovate-github-app-id.path}")
      INSTALLATION_ID=$(cat "${config.sops.secrets.renovate-installation-id.path}")

      # Decode the base64-encoded PEM key to a temp file
      PRIVATE_KEY="/run/renovate/app-key.pem"
      base64 -d < "${config.sops.secrets.renovate-github-app-key.path}" > "$PRIVATE_KEY"
      chmod 600 "$PRIVATE_KEY"

      # Base64url encode (no padding, URL-safe)
      b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

      # Build JWT header and payload
      now=$(date +%s)
      iat=$((now - 60))
      exp=$((now + 600))

      header=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
      payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$iat" "$exp" "$APP_ID" | b64url)

      # Sign with RSA private key
      signature=$(printf '%s.%s' "$header" "$payload" \
        | openssl dgst -sha256 -sign "$PRIVATE_KEY" | b64url)

      jwt="$header.$payload.$signature"

      # Exchange JWT for installation token
      token=$(curl -sf -X POST \
        -H "Authorization: Bearer $jwt" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" \
        | jq -r '.token')

      if [ -z "$token" ] || [ "$token" = "null" ]; then
        echo "ERROR: Failed to obtain installation token" >&2
        exit 1
      fi

      printf '%s' "$token" > /run/renovate/token
      chmod 600 /run/renovate/token
    '';
  };
in
{
  # Oneshot service — generates token then runs Renovate CLI
  systemd.services.renovate = {
    description = "Renovate dependency update bot";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RuntimeDirectory = "renovate";
      RuntimeDirectoryMode = "0700";
      ExecStartPre = "${generate-renovate-token}/bin/generate-renovate-token";
      ExecStart = pkgs.writeShellScript "renovate-run" ''
        set -euo pipefail
        TOKEN=$(cat /run/renovate/token)
        exec ${pkgs.podman}/bin/podman run --rm \
          --env RENOVATE_PLATFORM=github \
          --env RENOVATE_AUTODISCOVER=true \
          --env RENOVATE_TOKEN="$TOKEN" \
          --env LOG_LEVEL=info \
          ghcr.io/renovatebot/renovate:43.249.5
      '';
      # Hardening
      PrivateTmp = true;
    };
  };

  # Timer — daily at 5 AM
  systemd.timers.renovate = {
    description = "Run Renovate daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Persistent = true;
      RandomizedDelaySec = "5min";
    };
  };
}
