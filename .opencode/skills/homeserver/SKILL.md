---
name: homeserver
description: Manage the NixOS homeserver (wagoulab) — add services, configure secrets, DNS rewrites, Cloudflare Tunnel routes, Traefik reverse proxy, security hardening, and troubleshoot the Beelink EQI13.
---

## Overview

The homeserver (wagoulab) is a Beelink EQI13 running NixOS (x86_64-linux, 32 GB RAM, 512 GB NVMe) at IP `192.168.68.65`. It serves as a self-hosted service platform with network-wide ad blocking and secure remote access via Cloudflare Tunnel and Tailscale.

Domain: `wagou.fr` (registered at OVH, DNS managed by Cloudflare)

## Architecture

```
Remote access:  Browser -> Cloudflare (HTTPS) -> Tunnel (encrypted) -> Traefik (HTTPS :443) -> Service
Remote access:  SSH/LAN -> Tailscale (WireGuard) -> Beelink (subnet router) -> 192.168.68.0/24
Remote access:  Browser -> Tailscale (split DNS) -> AdGuard Home -> 192.168.68.65 -> Traefik -> Service
Local access:   Browser -> AdGuard Home (*.wagou.fr -> 192.168.68.65) -> Traefik (HTTPS :443) -> Service
```

All services run as Podman containers managed by quadlet-nix. They communicate over a shared `proxy` Podman network. Traefik serves HTTPS with Let's Encrypt wildcard certificates (DNS-01 via Cloudflare). The tunnel connects to Traefik over HTTPS (container-to-container, `noTLSVerify` since it's internal).

Tailscale runs as a native NixOS service (not a container) and acts as a subnet router, advertising the home LAN (`192.168.68.0/24`). This provides remote SSH access and access to any LAN device from anywhere. The Beelink's Tailscale IP is `100.68.157.70`.

IMPORTANT: AdGuard Home DNS rewrites for `*.wagou.fr` point to the local IP so LAN devices bypass Cloudflare and connect directly to Traefik HTTPS.
IMPORTANT: AdGuard Home DNS is published on `0.0.0.0:53` (all interfaces) so it's reachable via both LAN and Tailscale. The firewall restricts access to known interfaces only.

## Current services

| Service | NixOS config | Container port | Remote URL |
|---|---|---|---|
| Vaultwarden | `services/vaultwarden.nix` | 80 (Podman network) | `https://vault.wagou.fr` |
| OpenCloud | `services/opencloud.nix` | 9200 (Podman network) | `https://cloud.wagou.fr` |
| Immich | `services/immich.nix` | 2283 (Podman network) | `https://pixel.wagou.fr` |
| Homepage | `services/homepage.nix` | 3000 (Podman network) | `https://dash.wagou.fr` |
| Home Assistant | `services/home-assistant.nix` | 8123 (Podman network) | `https://home.wagou.fr` |
| Jellyfin | `services/jellyfin.nix` | 8096 (Podman network) | `https://tape.wagou.fr` |
| Traefik | `services/traefik.nix` | 80, 443 (published to host) | - |
| AdGuard Home | `services/adguardhome.nix` | 53 (published to host), 3000 (web UI) | `https://guard.wagou.fr` |
| Cloudflare Tunnel | `services/cloudflared.nix` | Outbound only | - |
| Tailscale | `services/tailscale.nix` | Native NixOS service (subnet router) | - |
| Fail2ban | `services/fail2ban.nix` | - | - |

## Files

### Host-level config: `hosts/nixos/wagoulab/`

| File | Purpose |
|---|---|
| `default.nix` | Imports `hardware.nix` and `services/` |
| `variables.nix` | Host variables: `username = "wagou"`, `hostname = "wagoulab"`, `domain = "wagou.fr"`, `serverIP = "192.168.68.65"`, `timezone`, `acmeEmail`, `cloudflareAccountId`, `cloudflareTunnelId`, `tunnelSubdomains` |
| `hardware.nix` | Auto-generated hardware config from `nixos-generate-config` (boot, filesystems, kernel modules, Intel microcode) |

### Services: `hosts/nixos/wagoulab/services/`

| File | Purpose |
|---|---|
| `default.nix` | Imports all service modules + system packages (ghostty.terminfo) |
| `podman.nix` | Podman runtime, quadlet-nix shared `proxy` network |
| `secrets.nix` | sops-nix secret declarations and templates |
| `traefik.nix` | Traefik reverse proxy container (Let's Encrypt, HSTS headers, Cloudflare trusted IPs) |
| `vaultwarden.nix` | Password manager container |
| `opencloud.nix` | File sync & sharing container |
| `immich.nix` | Photo management (server, ML, PostgreSQL, Redis — 4 containers + internal network) |
| `adguardhome.nix` | DNS server container, ad blocking, blocklists, local DNS rewrites |
| `cloudflared.nix` | Cloudflare Tunnel container |
| `tailscale.nix` | Tailscale VPN (native NixOS service, subnet router for `192.168.68.0/24`) |
| `homepage.nix` | Homepage dashboard container (Catppuccin Mocha theme, service widgets, nginx image sidecar) |
| `homepage-images/` | Background images and favicon for Homepage dashboard |
| `home-assistant.nix` | Home automation container |
| `jellyfin.nix` | Media server container with Intel hardware transcoding |
| `fail2ban.nix` | Brute force protection |
| `firewall.nix` | Firewall rules (ports 22, 53, 80, 443) |

### Platform-level NixOS config: `hosts/nixos/`

| File | Purpose |
|---|---|
| `default.nix` | Imports configuration.nix |
| `configuration.nix` | SSH (hardened, key-only), user account, timezone, locale, auto-updates |

### Secrets: `hosts/nixos/wagoulab/`

| File | Purpose |
|---|---|
| `secrets.yaml` | sops-encrypted secrets (age encryption, keys readable, values encrypted) |

### Config: repo root

| File | Purpose |
|---|---|
| `.sops.yaml` | Defines age public keys and encryption rules for sops |

## Security

| Layer | Implementation |
|---|---|
| **SSH** | Key-only auth, password disabled, root login disabled (`hosts/nixos/configuration.nix`) |
| **Fail2ban** | Bans IPs after 5 failed SSH attempts for 1 hour (`services/fail2ban.nix`) |
| **Firewall** | Only ports 22 (SSH), 53 (DNS), 80 (HTTP redirect), 443 (HTTPS) open |
| **Service isolation** | All services on Podman internal network, behind Traefik reverse proxy |
| **Secrets** | sops-nix with age encryption, decrypted to tmpfs (`/run/secrets/`) |
| **Vaultwarden** | Signups disabled, admin panel protected with sops-managed token |
| **Network** | No open ports on router, all external traffic through Cloudflare Tunnel |
| **TLS** | Let's Encrypt wildcard certificate (DNS-01 via Cloudflare), served by Traefik |
| **DNS** | AdGuard Home with DNS-over-HTTPS upstream |
| **Rate limiting** | Cloudflare WAF rate limiting on `*.wagou.fr` |
| **Auto-updates** | Daily rebuild at 4:00 AM from flake (`system.autoUpgrade`) |

## Secrets management (sops-nix)

Secrets are encrypted with age in `hosts/nixos/wagoulab/secrets.yaml` (colocated with the host config) and committed to Git. They are decrypted at NixOS activation time on the Beelink using its SSH host key.

### Current secrets

| Secret key | Used by | Mechanism |
|---|---|---|
| `cloudflare-credentials` | `cloudflared.nix` | Credentials file for tunnel auth |
| `opencloud-admin-password` | `opencloud.nix` | Via sops template `opencloud.env` |
| `vaultwarden-admin-token` | `vaultwarden.nix` | Via sops template `vaultwarden.env` |
| `immich-db-username` | `immich.nix` | Via sops templates `immich.env` and `immich-postgres.env` |
| `immich-db-password` | `immich.nix` | Via sops templates `immich.env` and `immich-postgres.env` |
| `wagou-password-hash` | `configuration.nix` | User password hash (neededForUsers) |
| `root-password-hash` | `configuration.nix` | Root password hash (neededForUsers) |
| `immich-api-key` | `homepage.nix` | Via sops template `homepage.env` |
| `adguard-password` | `homepage.nix` | Via sops template `homepage.env` |
| `cloudflare-tunnel-token` | `homepage.nix` | Via sops template `homepage.env` |
| `cloudflare-dns-token` | `traefik.nix` (ACME) | Via sops template `traefik.env` |
| `jellyfin-api-key` | `homepage.nix` | Via sops template `homepage.env` |

### Encryption keys

| Key | Purpose |
|---|---|
| Admin age key (`.sops.yaml`) | Public key for encrypting. Generated with `age-keygen`, standalone (not SSH-derived) |
| Admin age private key (`~/.config/sops/age/keys.txt`) | Private key on Mac for decrypting/editing secrets |
| Homeserver SSH host key (`/etc/ssh/ssh_host_ed25519_key`) | Private key on Beelink for decrypting at activation (converted to age internally by sops-nix) |

### Editing secrets

```bash
# From the wagounix directory:
sops hosts/nixos/wagoulab/secrets.yaml
# Or in Neovim (sops.nvim auto-decrypts):
nvim hosts/nixos/wagoulab/secrets.yaml
```

### Adding a new secret

1. Edit `hosts/nixos/wagoulab/secrets.yaml` with `sops` — add a new key-value pair
2. Declare it in `services/secrets.nix` under `sops.secrets`
3. If the service needs `KEY=VALUE` env format, create a `sops.templates` entry:
   ```nix
   sops.templates."myservice.env" = {
     content = "SECRET_KEY=${config.sops.placeholder.my-secret}\n";
   };
   ```
4. Reference in the service config:
   - Raw secret: `config.sops.secrets.<name>.path` (resolves to `/run/secrets/<name>`)
   - Template: `config.sops.templates.<name>.path` (resolves to `/run/secrets/rendered/<name>`)

### Important notes about sops

- The admin age private key (`~/.config/sops/age/keys.txt`) is NOT in Git or chezmoi — it lives only on the Mac
- If you lose it, generate a new key with `age-keygen`, update `.sops.yaml` with the new public key, and re-encrypt all secrets with `sops updatekeys hosts/nixos/wagoulab/secrets.yaml`
- The standalone age key was used instead of SSH-derived key because the SSH key is passphrase-protected (ssh-to-age can't handle passphrase-protected keys)

## Network configuration

### Router (TP-Link Deco)

| Setting | Value |
|---|---|
| DHCP DNS server (IPv4) | `192.168.68.65` (Beelink) |
| Internet Connection DNS (IPv4) | `192.168.68.65` (primary), `1.1.1.1` (fallback) |
| Internet Connection DNS (IPv6) | Beelink's IPv6 (primary), `2606:4700:4700::1111` (fallback) |
| IPv6 | Enabled |
| DHCP reservation | Beelink MAC -> `192.168.68.65` |

### DNS behavior

| Scenario | Resolution path |
|---|---|
| `*.wagou.fr` (remote, no Tailscale) | Cloudflare DNS -> Cloudflare Tunnel -> Beelink (HTTPS) |
| `*.wagou.fr` (remote, Tailscale) | Split DNS -> AdGuard Home (`100.68.157.70:53`) -> `192.168.68.65` -> Tailscale subnet route -> Traefik (direct HTTPS) |
| `*.wagou.fr` (local devices) | AdGuard Home rewrite -> `192.168.68.65` (direct HTTPS, bypasses Cloudflare) |
| Ad/tracker domains (local) | AdGuard Home -> blocked (`0.0.0.0`) |
| Everything else | AdGuard Home -> upstream DoH (Cloudflare/Google) -> Internet |

### Tailscale DNS (split DNS)

> Human-readable documentation: see `hosts/nixos/wagoulab/README.md` -> "Tailscale (remote access)" section.

Tailscale is configured with **split DNS** in the admin console (admin.tailscale.com -> DNS):
- Domain `wagou.fr` uses custom nameserver `100.68.157.70` (Beelink's Tailscale IP)
- "Override local DNS" is **disabled** (so work/SAP network DNS still resolves corporate domains)

This means when Tailscale is connected:
- `*.wagou.fr` queries go to AdGuard Home via Tailscale -> resolves to `192.168.68.65` -> routed via subnet tunnel -> Traefik
- All other DNS queries use the local network's DNS (no conflict with corporate VPN/DNS)
- Ad blocking only applies to `wagou.fr` resolution when remote (not global)

The `0.0.0.0:53` binding in `adguardhome.nix` ensures AdGuard responds on all interfaces (LAN + Tailscale). The firewall explicitly allows port 53 on the `tailscale0` interface.

### UDP GRO optimization

A systemd oneshot service (`tailscale-ethtool`) runs on boot to enable UDP GRO forwarding on the physical NIC (`enp170s0`), improving subnet router throughput. See `services/tailscale.nix`.

### Domain setup

| Component | Provider |
|---|---|
| Domain registrar | OVH (`wagou.fr`) |
| DNS | Cloudflare (OVH nameservers pointed to Cloudflare) |
| TLS certificates | Let's Encrypt (wildcard via DNS-01, Cloudflare DNS) |
| Email | OVH Zimbra (MX records in Cloudflare) |
| Bare domain redirect | Cloudflare redirect rule: `wagou.fr` -> `https://dash.wagou.fr` (configured in Cloudflare dashboard, not in NixOS) |

## AdGuard Home configuration

Runs as a Podman container with a seed config. The declarative config from Nix is copied into the container on every start, ensuring it's always the starting point. AdGuard may migrate the schema at runtime, which is fine — the seed is reapplied on each container restart.

### Upstream DNS
- `https://dns.cloudflare.com/dns-query` (DNS-over-HTTPS)
- `https://dns.google/dns-query` (DNS-over-HTTPS)

### Blocklists

| Name | URL |
|---|---|
| AdGuard DNS filter | `https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt` |
| Steven Black's Unified Hosts | `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` |
| Malicious URL Blocklist | `https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt` |

## Traefik routing

Traefik discovers services via the Docker/Podman provider. Each container declares Traefik labels to configure its router, TLS, and middlewares. All services share the `secure-headers@file` middleware (HSTS, X-Content-Type-Options, XSS protection).

Routing is determined by `Host()` rules matching the subdomain:

| Subdomain | Container | Container port | Notes |
|---|---|---|---|
| `vault.wagou.fr` | vaultwarden | 80 | `IP_HEADER = "X-Real-IP"` for audit logs |
| `pixel.wagou.fr` | immich-server | 2283 | - |
| `cloud.wagou.fr` | opencloud | 9200 | `OC_INSECURE = "true"` (behind Traefik) |
| `guard.wagou.fr` | adguard | 3000 | Web UI |
| `dash.wagou.fr` | homepage-images (nginx) | 8090 | Static images at `/bg/*` |
| `dash.wagou.fr` | homepage | 3000 | Dashboard (default route) |
| `home.wagou.fr` | home-assistant | 8123 | - |
| `tape.wagou.fr` | jellyfin | 8096 | Intel VAAPI/QSV hardware transcoding |

## SSH access

> Also documented in `hosts/nixos/wagoulab/README.md` -> "SSH access" section.

SSH is hardened — key-only authentication, no passwords, no root login.

### SSH config on Mac (`~/.ssh/config`, managed by chezmoi)

```
Host wagoulab
    HostName 192.168.68.65
    User wagou
    IdentityFile ~/.ssh/id_ed25519_homeserver
    AddKeysToAgent yes
    UseKeychain yes
```

Connect with: `ssh wagoulab`

### Authorized key

The homeserver SSH public key is declared in `hosts/nixos/configuration.nix` under `users.users.wagou.openssh.authorizedKeys.keys`. This is the `id_ed25519_homeserver` key (separate from the SAP work SSH key for identity separation).

## Adding a new service

### Step 1 — Create the service file

Create `services/<newservice>.nix` with a Podman container definition:

```nix
{ config, host, ... }:

let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet.containers.newservice = {
    containerConfig = {
      image = "org/newservice:latest";
      networks = [ networks.proxy.ref ];
      volumes = [ "/var/lib/newservice:/data" ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.newservice.rule" = "Host(`newservice.${host.domain}`)";
        "traefik.http.routers.newservice.entrypoints" = "websecure";
        "traefik.http.routers.newservice.tls" = "true";
        "traefik.http.routers.newservice.middlewares" = "secure-headers@file";
        "traefik.http.services.newservice.loadbalancer.server.port" = "<port>";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/newservice 0755 root root -"
  ];
}
```

### Step 2 — Import it

Add `./newservice.nix` to the imports in `services/default.nix`.

### Step 3 — Add subdomain to variables

Add the subdomain to `tunnelSubdomains` in `hosts/nixos/wagoulab/variables.nix`:

```nix
tunnelSubdomains = [ "vault" "pixel" "cloud" "home" "guard" "tape" "newservice" ];
```

This automatically wires up:
- DNS rewrite in AdGuard Home (local HTTPS bypass)
- Tunnel ingress rule in cloudflared (remote access)

### Step 4 — Add secrets (if needed)

In `services/secrets.nix`:

```nix
sops.secrets.newservice-secret = { mode = "0400"; };

# If the service needs KEY=VALUE env format:
sops.templates."newservice.env" = {
  content = "SECRET=${config.sops.placeholder.newservice-secret}\n";
};
```

Then edit `hosts/nixos/wagoulab/secrets.yaml` with `sops` to add the secret value.

### Step 5 — Add Cloudflare DNS route

Run `cloudflared tunnel route dns wagoulab newservice.wagou.fr` once from your Mac (requires `cert.pem` from `cloudflared login`).

### Step 6 — Deploy

```bash
git add -A && git commit -m "feat: add newservice" && git push
sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagoulab --refresh
```

## Troubleshooting

> Full troubleshooting guide: see `hosts/nixos/wagoulab/README.md` -> "Troubleshooting" section.

### OpenCloud "Permanent Redirect" loop

OpenCloud redirects HTTP to HTTPS because its URL is configured as `https://cloud.wagou.fr`. The fix is `OC_INSECURE = "true"` and `PROXY_TLS = "false"` in the container environment, which tells OpenCloud to accept plain HTTP behind Traefik.

### OpenCloud fails to start ("Failed to load environment files")

sops-nix decrypts secrets during the NixOS activation script (before services start). If OpenCloud still can't find its environment file, check:
1. `sudo ls -la /run/secrets/rendered/opencloud.env` — should exist
2. `journalctl -u opencloud --no-pager | tail -20` — check for specific error
3. sops-nix does NOT use a systemd service — do NOT add `after = [ "sops-nix.service" ]`

### Ghostty terminal error when SSHing

If you see `'xterm-ghostty': unknown terminal type`, the `ghostty.terminfo` package is installed on the server. If it happens again, run `export TERM=xterm-256color` as a workaround.

### Cloudflare Tunnel not connecting

1. `systemctl status cloudflared` (quadlet-nix container unit)
2. `journalctl -u cloudflared --no-pager -f`
3. Common error: "couldn't read tunnel credentials" — check `cloudflare-credentials` sops secret and credentials-file path

### 502 Bad Gateway from Cloudflare

Tunnel connected but service not responding:
1. Is Traefik running? `systemctl status traefik`
2. Is the service running? `systemctl status <service>`
3. Check Traefik logs: `journalctl -u traefik --no-pager -f`
4. Ensure the container is on the `proxy` network and has correct Traefik labels

### DNS not resolving locally

1. `scutil --dns | grep nameserver` — should show `192.168.68.65`
2. Force DHCP renewal: `sudo ipconfig set en0 DHCP`
3. Test directly: `nslookup vault.wagou.fr 192.168.68.65`
4. Do NOT use `.local` domains — macOS intercepts them for mDNS. Use `*.wagou.fr` with AdGuard Home rewrites.

### "Internet not available" on macOS

If IPv6 is enabled on the Deco and the Beelink's IPv6 DNS is configured, this should not happen. If it does, check if `captive.apple.com` is being blocked in AdGuard Home query log. If so, add an allowlist rule.

### Can't decrypt sops secrets (on Mac)

Ensure `~/.config/sops/age/keys.txt` exists and contains your age private key. If not, regenerate with `age-keygen -o ~/.config/sops/age/keys.txt` and update the public key in `.sops.yaml`, then re-encrypt with `sops updatekeys hosts/nixos/wagoulab/secrets.yaml`.

## Key commands

| Action | Command |
|---|---|
| SSH into server | `ssh wagoulab` |
| Rebuild from GitHub | `sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagoulab --refresh` |
| Check service status | `systemctl status <service>` |
| View service logs | `journalctl -u <service> --no-pager -f` |
| Stop/start a service | `sudo systemctl stop/start <service>` |
| Edit secrets | `sops hosts/nixos/wagoulab/secrets.yaml` |
| Test build | `nix eval .#nixosConfigurations.wagoulab.config.system.build.toplevel.drvPath` |

## Important rules

- Each service gets its own file in `services/` — one service per file
- All services run as Podman containers via quadlet-nix on the `proxy` network
- Traefik discovers services via Docker/Podman labels — no manual routing config needed
- Secrets go in `hosts/nixos/wagoulab/secrets.yaml` (encrypted with sops, colocated with the host config) — NEVER as plain files on the server
- AdGuard Home DNS rewrites need `enabled = true` — defaults to `false`
- Traefik serves HTTPS with Let's Encrypt wildcard cert
- Cloudflare Tunnel routes use HTTPS to `traefik:443` (container network) with `noTLSVerify = true`
- AdGuard Home DNS rewrites for `*.wagou.fr` point to the local IP so LAN devices bypass Cloudflare
- `system.stateVersion = "25.05"` — never change this
- `hardware.nix` was generated by `nixos-generate-config` — only regenerate if hardware changes
- Always test builds before pushing: `nix eval .#nixosConfigurations.wagoulab.config.system.build.toplevel.drvPath`
- SSH uses a dedicated key (`id_ed25519_homeserver`), separate from work SSH key
