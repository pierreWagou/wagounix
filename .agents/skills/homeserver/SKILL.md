---
name: homeserver
description: Manage the NixOS homeserver (wagoulab) — add services, configure secrets, DNS rewrites, Cloudflare Tunnel routes, Traefik reverse proxy, security hardening, backups, failover, and troubleshoot the primary/backup setup.
---

## Overview

The homeserver runs as a **warm standby** primary/backup pair serving self-hosted services with network-wide ad blocking and secure remote access.

| Machine | Role | Hardware | LAN IP | Tailscale IP | Cloudflare Tunnel |
|---|---|---|---|---|---|
| **wagou-prime** | Primary | Beelink | `192.168.68.66` | `100.97.36.56` | `wagou-prime` |
| **wagou-clone** | Backup | Different hardware | `192.168.68.62` | `100.81.107.72` | `wagou-clone` |

Domain: `wagou.fr` (registered at OVH, DNS managed by Cloudflare)

Both machines share `wagoulab/common/` (services + shared secrets) via the wagounix flake — prime and clone differ only in their `hosts/nixos/wagoulab/{prime,clone}/` layer (`variables.nix`, `hardware.nix`). The clone disables all quadlet containers by default (`clone/services-disabled.nix`) and sits idle until failover.

## Primary/Backup Architecture

```
                              Cloudflare DNS
                          *.wagou.fr → CNAME
                              ┌──────┴──────┐
                              │             │
                    wagou-prime tunnel  wagou-clone tunnel
                    (when primary      (currently active)
                     is live)
                              │             │
              ┌───────────────┤             ├───────────────┐
              │    Tailscale  │             │    Tailscale  │
              │   (encrypted) │             │   (encrypted) │
              └───────┬───────┘             └───────┬───────┘
                      │                             │
         ┌────────────▼────────────┐   ┌────────────▼────────────┐
         │    Primary (wagou-prime)│   │    Backup (wagou-clone) │
         │    192.168.68.66        │   │    192.168.68.62        │
         │    All services running │   │    Services idle (disabled)│
         │    Restic backup source │◄──┤    Restic repository     │
         └─────────────────────────┘   │    (warm standby)        │
                                       └─────────────────────────┘
```

### How it works

- **Primary** pushes hourly Restic backups (including database dumps) to the backup machine via SSH
- After each backup, the backup machine **restores** the snapshot to regular files so services can read them
- **File-based data** (Vaultwarden, Immich uploads, Seafile, HA) is always current on backup
- **Database data** (Immich, Authentik, Seafile) is restored from dumps on each hourly cycle
- On primary failure: switch DNS CNAME to backup tunnel → services are live on backup machine

### Cloudflare Tunnel naming

| Tunnel | ID | Machine | Purpose |
|---|---|---|---|
| `wagou-prime` | `ca26559c-2858-4c78-867e-41e3c19edb52` | Primary | Active when primary is live |
| `wagou-clone` | `b1054c2d-9146-421d-9beb-4efe75a4b25f` | Backup | Active during failover |

DNS CNAME records currently point to wagou-clone (backup is live). When primary arrives, CNAMEs switch to wagou-prime.

IMPORTANT: `cloudflared tunnel route dns` creates individual CNAME records per hostname, not wildcards. A wildcard `*.wagou.fr` CNAME exists but specific records take precedence. During failover, update all individual CNAMEs:
```bash
for sub in dash vault pixel guard home tape dev relay cabas auth disk docs pantone assets mailbox crawl; do
  TUNNEL_FORCE_PROVISIONING_DNS=true cloudflared tunnel route dns wagou-prime "$sub.wagou.fr"
done
```

### Variables that differ between machines

| Variable | wagou-prime (primary) | wagou-clone (backup) |
|---|---|---|
| `hostname` | `wagou-prime` | `wagou-clone` |
| `serverIP` | `192.168.68.66` | `192.168.68.62` |
| `cloudflareTunnelId` | `ca26559c-...` (wagou-prime) | `b1054c2d-...` (wagou-clone) |
| `networkInterface` | `enp170s0` | `enp1s0` |

Defined in `hosts/nixos/wagoulab/prime/variables.nix` and `hosts/nixos/wagoulab/clone/variables.nix` (subdomain lists mirrored).

## Backup Strategy

Restic backups run **hourly** from primary to backup machine via SSH. After each backup, the backup machine **restores** the snapshot to regular files so services can run on current data.

### What's backed up

| Directory | Service | Priority |
|---|---|---|
| `/var/lib/vaultwarden` | Vaultwarden | Critical |
| `/var/lib/immich` | Immich (photos) | High |
| `/var/lib/immich-postgres` | Immich DB | High |
| `/var/lib/seafile` | Seafile (files) | High |
| `/var/lib/seafile-mysql` | Seafile DB | High |
| `/var/lib/authentik` | Authentik | High |
| `/var/lib/authentik-postgres` | Authentik DB | High |
| `/var/lib/home-assistant` | Home Assistant | High |
| `/var/lib/stalwart` | Stalwart Mail | Medium |
| `/var/lib/stalwart-config` | Stalwart config | Medium |
| `/var/lib/kitchenowl` | KitchenOwl | Low |
| `/var/lib/satisfactory` | Satisfactory saves | Low |
| `/var/lib/adguardhome/conf` | AdGuard config | Medium |
| `/var/lib/jellyfin/config` | Jellyfin config | Medium |
| `/var/lib/dokploy` | Dokploy | Medium |
| `/tmp/restic-dumps/*` | Database dumps | High |

**Excluded:** `/var/lib/immich-ml-cache`, `/var/lib/jellyfin/cache`, `/var/lib/traefik/letsencrypt`, `/var/lib/adguardhome/work`, `/var/lib/satisfactory/gamefiles` (2.8 GB), `/var/lib/*/redis`, `*/logs/*`, `/var/backup`

### Database dumps (pre-backup)

Before each Restic backup, database dumps are created:

```bash
sudo podman exec immich-postgres pg_dump -U postgres -Fc immich > /tmp/restic-dumps/immich.dump
sudo podman exec authentik-postgres pg_dump -U authentik -Fc authentik > /tmp/restic-dumps/authentik.dump
sudo podman exec seafile-db mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases > /tmp/restic-dumps/seafile.sql
```

### Restic repository

- **Location**: `/var/backup/restic` on backup machine
- **Access**: SSH/SFTP from primary
- **Retention**: 7 daily, 4 weekly, 6 monthly
- **Encryption**: Restic built-in (password via sops)

### Key backup commands

| Action | Command |
|---|---|
| List snapshots | `restic -r /var/backup/restic snapshots` |
| Restore latest | `restic -r /var/backup/restic restore latest --target /` |
| Restore specific | `restic -r /var/backup/restic restore <snapshot-id> --target /` |
| Check repo integrity | `restic -r /var/backup/restic check` |

## Failover Procedure

### When primary dies (RTO: ~10-15 min, RPO: ~1 hour)

1. **Restore database dumps** on backup machine:
   ```bash
   sudo podman exec immich-postgres pg_restore -U postgres immich < /tmp/restore/immich.dump
   sudo podman exec authentik-postgres pg_restore -U authentik authentik < /tmp/restore/authentik.dump
   sudo podman exec seafile-db mysql < /tmp/restore/seafile.sql
   sudo systemctl restart immich authentik seafile
   ```
2. **Switch Cloudflare DNS**:
   ```bash
   for sub in dash vault pixel guard home tape dev relay cabas auth disk docs pantone assets mailbox crawl; do
     TUNNEL_FORCE_PROVISIONING_DNS=true cloudflared tunnel route dns wagou-clone "$sub.wagou.fr"
   done
   ```
3. **Switch game server A record**: `satisfactory.wagou.fr` → backup's public IP
4. **Switch MX record**: `wagou.fr` → backup's public IP
5. **Verify**: `curl -I https://dash.wagou.fr`

**File-based services** (Vaultwarden, Immich photos, Seafile files, HA, etc.) are already current on backup — no restore needed. Only database-backed services (Immich, Authentik, Seafile DBs) need the dump/restore step.

### When new primary arrives

1. Install NixOS, deploy wagoulab config
2. Restore data from backup via Restic
3. Switch Cloudflare DNS to wagou-prime:
   ```bash
   for sub in dash vault pixel guard home tape dev relay cabas auth disk docs pantone assets mailbox crawl; do
     TUNNEL_FORCE_PROVISIONING_DNS=true cloudflared tunnel route dns wagou-prime "$sub.wagou.fr"
   done
   ```
4. Update game server A record and MX record → primary's public IP
5. Move port forwarding on home router → primary IP

### When backup moves to parents' home

1. Update `wagou-clone/variables.nix`: `serverIP` → parents' LAN IP, `tailscaleIP` → new Tailscale IP, `networkInterface` → actual NIC
2. Set up port forwarding on parents' router (same ports as primary)
3. Backups continue over Tailscale

### Port forwarding

| Port | Protocol | Purpose |
|---|---|---|
| 7777, 8888 | TCP+UDP | Satisfactory game server |
| 25, 465, 587 | TCP | Stalwart SMTP |
| 143, 993, 4190 | TCP | Stalwart IMAP/Sieve |

Port forwarding switches to whichever machine is active. Cloudflare Tunnel (web services) needs no port forwarding.

### Services vs Apps — two-tier deployment model

The homeserver uses a **two-tier deployment model**:

| Tier | What | Managed by | Container runtime | Config location |
|---|---|---|---|---|
| **Services** | Infrastructure & homelab services (Vaultwarden, Immich, Jellyfin, etc.) | NixOS / quadlet-nix | Podman | `hosts/nixos/wagoulab/common/services/<name>/` (dir per service, via `lib/web-service.nix`) |
| **Apps** | User-built applications (creneau, future apps) | Dokploy | Docker (Swarm) | Dokploy UI + app repo `docker-compose.yml` |

**Services** are declared in the wagounix flake and deployed via `nixos-rebuild switch`. They run as Podman containers on the shared `proxy` network, discovered by Traefik via Podman labels.

**Apps** are deployed via **Dokploy** (`apps.wagou.fr`), a self-hosted PaaS running as a Docker Swarm stack on the same server. Dokploy manages container lifecycle, rolling deploys, environment variables, and volumes. Apps use pre-built Docker images from GHCR (built by CI — never built on the server).

### Routing architecture

```
serviceTunnelSubdomains  →  NixOS Traefik → Podman container (direct)
appTunnelSubdomains      →  NixOS Traefik → Dokploy Traefik (127.0.0.1:9080) → Docker container
```

Both lists are defined per machine in `hosts/nixos/wagoulab/{prime,clone}/variables.nix` (keep them mirrored). Adding a subdomain to either list automatically wires up:
- Cloudflare Tunnel ingress rule
- AdGuard Home DNS rewrite
- NixOS Traefik router (either direct or forwarded to Dokploy)

### Container runtimes

- **Podman** (quadlet-nix): used for NixOS-managed services. Containers on the `proxy` Podman network. Traefik listens on the Podman socket (`/run/podman/podman.sock`) for label discovery.
- **Docker Swarm** (Dokploy): used for user apps. Containers on the `apps` Docker overlay network. Dokploy has its own Traefik instance on port 9080 (internal) that NixOS Traefik forwards app subdomains to.

Tailscale runs as a native NixOS service (not a container) and acts as a subnet router, advertising the home LAN (`192.168.68.0/24`). This provides remote SSH access and access to any LAN device from anywhere. The Beelink's Tailscale IP is `100.97.36.56`.

IMPORTANT: AdGuard Home DNS rewrites for `*.wagou.fr` point to the local IP so LAN devices bypass Cloudflare and connect directly to Traefik HTTPS.
IMPORTANT: AdGuard Home DNS is published on specific IPs (`192.168.68.66`, Tailscale IP, `127.0.0.1`) on port 53, mapped to container port 5353. This avoids conflicts with Podman's aardvark-dns which binds port 53 on bridge gateway IPs. The firewall restricts access to known interfaces only.

## Current services

### NixOS-managed services (Podman / quadlet-nix)

| Service | NixOS config | Container port | Remote URL |
|---|---|---|---|
| Vaultwarden | `services/vaultwarden/` | 80 (Podman network) | `https://vault.wagou.fr` |
| Seafile | `services/seafile/` | 80 (Podman network) | `https://disk.wagou.fr` |
| Immich | `services/immich/` | 2283 (Podman network) | `https://pixel.wagou.fr` |
| Homepage | `services/homepage/` | 3000 (Podman network) | `https://dash.wagou.fr` |
| Home Assistant | `services/home-assistant/` | 8123 (Podman network) | `https://home.wagou.fr` |
| Jellyfin | `services/jellyfin/` | 8096 (Podman network) | `https://tape.wagou.fr` |
| Traefik | `services/traefik/` | 80, 443 (published to host) | - |
| AdGuard Home | `services/adguardhome/` | 5353 (mapped to host:53 on LAN/Tailscale/lo), 3000 (web UI) | `https://guard.wagou.fr` |
| Cloudflare Tunnel | `services/cloudflared/` | Outbound only | - |
| Tailscale | `services/tailscale.nix` | Native NixOS service (subnet router) | - |
| Fail2ban | `services/fail2ban.nix` | - | - |
| ttyd | `services/ttyd.nix` | 7681 (native systemd service) | `https://dev.wagou.fr` |
| rbw | `services/rbw.nix` | - (custom pinentry script) | - |
| Webhook | `services/webhook/` | 9000 (host service, native) | `https://relay.wagou.fr` |
| Renovate | `services/renovate/` | - (systemd oneshot + timer) | - |
| KitchenOwl | `services/kitchenowl/` | 8080 (Podman network) | `https://cabas.wagou.fr` |
| Authentik | `services/authentik/` | 9000 (Podman network) | `https://auth.wagou.fr` |
| OnlyOffice | `services/onlyoffice/` | 80 (Podman network) | internal (Seafile integration) |
| Penpot | `services/penpot/` | 9001 (Podman network) | `https://pantone.wagou.fr` |
| Stalwart Mail | `services/stalwart/` | 8080 (Podman network) | `https://mailbox.wagou.fr` |
| OmniGent | `services/omnigent/` | 8000 (Podman network) | `https://ai.wagou.fr` |
| Firecrawl | `services/firecrawl/` | 3002 (Podman network) | `https://crawl.wagou.fr` |
| Satisfactory | `services/satisfactory.nix` | host networking (UDP/TCP 7777, 8888) | `satisfactory.wagou.fr` (DNS-only, no HTTPS) |
| Branding (imgproxy) | `services/branding.nix` | 8080 (Podman network) | `https://assets.wagou.fr` |
| Dokploy | `services/dokploy/` | 3001 (UI, published to 127.0.0.1), 9080 (Traefik, internal) | `https://apps.wagou.fr` |

### Dokploy-managed apps (Docker Swarm)

| App | Image | Remote URL | Notes |
|---|---|---|---|
| Creneau (prod) | `ghcr.io/pierrewagou/creneau:latest` | `https://creneau.wagou.fr` | Persistent bind mount `/var/lib/creneau:/app/data`, no `SEED_ON_INIT` |
| Creneau (preview) | `ghcr.io/pierrewagou/creneau:latest` | `https://creneau-preview.wagou.fr` | `SEED_ON_INIT=true`, seeded with fake data on first boot |

## Files

### Host layers: `hosts/nixos/wagoulab/{common,prime,clone}/`

| File | Purpose |
|---|---|
| `common/default.nix` | Imports `services/` (shared by prime + clone) |
| `common/secrets.yaml` | Shared sops-encrypted secrets (age encryption, keys readable, values encrypted) |
| `prime/default.nix` | Imports `hardware.nix` + `../common` |
| `prime/variables.nix` | Primary vars: `username`, `hostname` (`wagou-prime`), `domain`, `serverIP`, `tailscaleIP`, `networkInterface`, `lanSubnet`, `renderGroupGid`, `timezone`, `acmeEmail`, `adminEmail`, `cloudflareAccountId`, `cloudflareTunnelId` (wagou-prime), `serviceTunnelSubdomains` (NixOS-managed), `appTunnelSubdomains` (Dokploy-managed), `dnsOnlySubdomains`, `valkeyImage`, `podmanCIDRs`, `ports`, `latitude`, `longitude` |
| `prime/hardware.nix` | Auto-generated hardware config from `nixos-generate-config` (boot, filesystems, kernel modules) |
| `clone/default.nix` | Imports `hardware.nix` + `../common` + `services-disabled.nix` |
| `clone/variables.nix` | Backup vars (same shape, `wagou-clone` values; subdomain lists mirrored) |
| `clone/hardware.nix` | Backup-specific hardware config |
| `clone/services-disabled.nix` | Disables all quadlet containers by default (idle warm standby) |

### Services: `hosts/nixos/wagoulab/common/services/`

One dir per service — `<name>/default.nix` (+ `<name>/secrets.yaml` if it needs secrets), built with `lib/web-service.nix` (`mkWebService` / `mkPostgres` / `mkValkey`).

| File | Purpose |
|---|---|
| `default.nix` | Imports all service dirs |
| `lib/web-service.nix` | Shared helpers: `mkWebService` (proxy network, `noNewPrivileges`, Traefik labels), `mkPostgres`, `mkValkey` |
| `podman.nix` | Podman runtime, quadlet-nix shared `proxy` network |
| `secrets.nix` | Shared-only sops-nix declarations (`cloudflare-dns-token`, password hashes, `rbw-master-password`); per-service secrets live in `<name>/secrets.yaml` with `sopsFile = ./secrets.yaml` |
| `traefik/` | Traefik reverse proxy container (Let's Encrypt, HSTS headers, Cloudflare trusted IPs) |
| `vaultwarden/` | Password manager container |
| `seafile/` | File sync & sharing (Seafile MC + SeaDoc + MariaDB + Redis, OIDC SSO via Authentik) |
| `immich/` | Photo management (server, ML, PostgreSQL, Redis — 4 containers + internal network) |
| `adguardhome/` | DNS server container, ad blocking, blocklists, local DNS rewrites |
| `cloudflared/` | Cloudflare Tunnel container |
| `tailscale.nix` | Tailscale VPN (native NixOS service, subnet router for `192.168.68.0/24`) |
| `homepage/` | Homepage dashboard container (Catppuccin theme via branding module, service widgets, imgproxy backgrounds) |
| `authentik/` | Identity provider / SSO — OIDC (server, worker, PostgreSQL, Redis) |
| `onlyoffice/` | Document server (Seafile integration) |
| `penpot/` | Design & prototyping (frontend + backend + PostgreSQL + Valkey) |
| `stalwart/` | Email server (LDAP auth via Authentik) |
| `omnigent/` | AI agent gateway (server + PostgreSQL, OIDC via Authentik) |
| `firecrawl/` | Web scraping API (api + Playwright + Redis + RabbitMQ + Postgres + SearXNG) |
| `branding.nix` | Shared Catppuccin theme + imgproxy assets server (logos, backgrounds, favicon, CSS) |
| `branding-assets/` | Source images and favicon served via imgproxy (`assets.wagou.fr`) |
| `home-assistant/` | Home automation container |
| `jellyfin/` | Media server container with Intel hardware transcoding |
| `fail2ban.nix` | Brute force protection |
| `firewall.nix` | Firewall rules (ports 22, 53, 80, 443) |
| `ttyd.nix` | Web terminal for remote dev access (Catppuccin theme, Nerd Font, native systemd service) |
| `rbw.nix` | Custom pinentry script for rbw (reads master password from sops secret) |
| `satisfactory.nix` | Game server (host networking, raw UDP/TCP — DNS-only subdomain) |
| `dokploy/` | Dokploy PaaS — Docker Swarm stack (postgres, redis, traefik, ui), published at `apps.wagou.fr` |
| `webhook/` | GitHub webhook receiver (triggers rebuilds + Renovate) |
| `renovate/` | Dependency update bot (systemd oneshot + timer + token script) |
| `kitchenowl/` | Recipes & grocery lists container |

### Platform-level NixOS config: `hosts/nixos/`

| File | Purpose |
|---|---|
| `default.nix` | Imports `configuration.nix` and `packages.nix` |
| `configuration.nix` | SSH (hardened, key-only), user account, timezone, locale, auto-updates |

### Secrets: `hosts/nixos/wagoulab/common/` + per-service dirs

| File | Purpose |
|---|---|
| `common/secrets.yaml` | Shared sops-encrypted secrets (age encryption, keys readable, values encrypted) |
| `common/services/<name>/secrets.yaml` | Per-service secrets, colocated with the service module (`.sops.yaml` covers `services/*/secrets.yaml`) |

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

Secrets are encrypted with age and committed to Git, decrypted at NixOS activation time using the machine's SSH host key. Two locations:

- **Shared** (`hosts/nixos/wagoulab/common/secrets.yaml`, declared in `common/services/secrets.nix`): `cloudflare-dns-token`, `wagou-password-hash`, `root-password-hash`, `rbw-master-password`
- **Per service** (`common/services/<name>/secrets.yaml`, declared in `<name>/default.nix` with `sopsFile = ./secrets.yaml`): everything else — each service owns its keys (e.g. `vaultwarden-admin-token`, `immich-*`, `authentik-*`, `seafile-*`, `omnigent-*`, `penpot-*`, `stalwart-*`)

`.sops.yaml` has three rules: `common/secrets.yaml`, `clone/secrets.yaml`, and `common/services/*/secrets.yaml` (all readable by admin + wagou-prime + wagou-clone + wagou-mac keys).

### Current secrets (per-service files)

| Secret key | Used by | Mechanism |
|---|---|---|
| `cloudflare-credentials-prime` | `cloudflared/` (primary) | Credentials file for wagou-prime tunnel |
| `cloudflare-credentials-clone` | `cloudflared/` (backup) | Credentials file for wagou-clone tunnel |
| `cloudflare-credentials` | DEPRECATED — removed, use prime/clone variants | - |
| `vaultwarden-admin-token` | `vaultwarden/` | Via sops template `vaultwarden.env` |
| `immich-db-username` | `immich/` | Via sops templates `immich.env` and `immich-postgres.env` |
| `immich-db-password` | `immich/` | Via sops templates `immich.env` and `immich-postgres.env` |
| `wagou-password-hash` | `configuration.nix` (shared) | User password hash (neededForUsers) |
| `root-password-hash` | `configuration.nix` (shared) | Root password hash (neededForUsers) |
| `immich-api-key` | `homepage/` | Via sops template `homepage.env` |
| `adguard-password` | `homepage/` | Via sops template `homepage.env` |
| `cloudflare-tunnel-token` | `homepage/` | Via sops template `homepage.env` |
| `cloudflare-dns-token` | `traefik/` (ACME) + `stalwart/` — shared | Via sops template `traefik.env` |
| `jellyfin-api-key` | `homepage/` | Via sops template `homepage.env` |
| `rbw-master-password` | `rbw.nix` (shared) | Raw secret file (owner: wagou, mode: 0400) |
| `github-webhook-secret` | `webhook/` | Via sops template `webhook.env` |
| `renovate-github-app-id` | `renovate/` | Raw secret file (token generation script) |
| `renovate-github-app-key` | `renovate/` | Raw secret file (base64-encoded PEM) |
| `renovate-installation-id` | `renovate/` | Raw secret file (token generation script) |
| `kitchenowl-jwt-secret` | `kitchenowl/` | Via sops template `kitchenowl.env` |
| `kitchenowl-oidc-client-secret` | `kitchenowl/` | OIDC client secret (Authentik SSO), via `kitchenowl.env` |
| `authentik-secret-key` | `authentik/` | Via sops template `authentik.env` |
| `authentik-postgres-password` | `authentik/` | Via `authentik.env` + `authentik-postgres.env` |
| `seafile-mysql-root-password` | `seafile/` | Via `seafile.env` + `seafile-db.env` |
| `seafile-mysql-password` | `seafile/` | Via sops template `seafile.env` |
| `seafile-jwt-key` | `seafile/` | Via sops template `seafile.env` |
| `seafile-secret-key` | `seafile/` | Via `seahub_settings.py` template |
| `seafile-oauth-client-secret` | `seafile/` | OIDC client secret (Authentik SSO), via `seahub_settings.py` |
| `onlyoffice-jwt-secret` | `onlyoffice/` | Via sops template |
| `penpot-*` | `penpot/` | DB password + secrets via templates |
| `stalwart-*` | `stalwart/` | Admin credentials + secrets via templates |
| `omnigent-postgres-password` | `omnigent/` | Via `omnigent-postgres.env` + `DATABASE_URL` in `omnigent.env` |
| `omnigent-cookie-secret` | `omnigent/` | Via `omnigent.env` |
| `omnigent-oidc-client-secret` | `omnigent/` | OIDC client secret (Authentik SSO), via `omnigent.env` |

### Encryption keys

| Key | Purpose |
|---|---|
| Admin age key (`.sops.yaml`) | Public key for encrypting. Generated with `age-keygen`, standalone (not SSH-derived) |
| Admin age private key (`~/.config/sops/age/keys.txt`) | Private key on Mac for decrypting/editing secrets |
| Homeserver SSH host key (`/etc/ssh/ssh_host_ed25519_key`) | Private key on Beelink for decrypting at activation (converted to age internally by sops-nix) |

### Editing secrets

```bash
# From the wagounix directory:
sops hosts/nixos/wagoulab/common/secrets.yaml                  # shared secrets
sops hosts/nixos/wagoulab/common/services/<name>/secrets.yaml  # per-service secrets
# Or in Neovim (sops.nvim auto-decrypts):
nvim hosts/nixos/wagoulab/common/services/<name>/secrets.yaml
```

### Adding a new secret

Shared secret (used by platform config or multiple services):

1. Edit `hosts/nixos/wagoulab/common/secrets.yaml` with `sops` — add a new key-value pair
2. Declare it in `common/services/secrets.nix` under `sops.secrets`

Per-service secret (used by one service):

1. Edit `common/services/<name>/secrets.yaml` with `sops` — add a new key-value pair
2. Declare it in `<name>/default.nix` with `sopsFile = ./secrets.yaml`:
   ```nix
   sops.secrets.my-secret = {
     sopsFile = ./secrets.yaml;
     mode = "0400";
   };
   ```
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
- If you lose it, generate a new key with `age-keygen`, update `.sops.yaml` with the new public key, and re-encrypt with `sops updatekeys <each secrets.yaml>` (shared + every per-service file)
- The standalone age key was used instead of SSH-derived key because the SSH key is passphrase-protected (ssh-to-age can't handle passphrase-protected keys)

## Network configuration

### Router (TP-Link Deco)

| Setting | Value |
|---|---|
| DHCP DNS server (IPv4) | `192.168.68.66` (Beelink) |
| Internet Connection DNS (IPv4) | `192.168.68.66` (primary), `1.1.1.1` (fallback) |
| Internet Connection DNS (IPv6) | Beelink's IPv6 (primary), `2606:4700:4700::1111` (fallback) |
| IPv6 | Enabled |
| DHCP reservation | Beelink MAC -> `192.168.68.66` |

### DNS behavior

| Scenario | Resolution path |
|---|---|
| `*.wagou.fr` (remote, no Tailscale) | Cloudflare DNS -> Cloudflare Tunnel -> Beelink (HTTPS) |
| `*.wagou.fr` (remote, Tailscale) | Split DNS -> AdGuard Home (`100.97.36.56:53`) -> `192.168.68.66` -> Tailscale subnet route -> Traefik (direct HTTPS) |
| `*.wagou.fr` (local devices) | AdGuard Home rewrite -> `192.168.68.66` (direct HTTPS, bypasses Cloudflare) |
| Ad/tracker domains (local) | AdGuard Home -> blocked (`0.0.0.0`) |
| Everything else | AdGuard Home -> upstream DoH (Cloudflare/Google) -> Internet |

### Tailscale DNS (split DNS)

> Human-readable documentation: see `hosts/nixos/wagoulab/common/README.md` -> "Tailscale (remote access)" section.

Tailscale is configured with **split DNS** in the admin console (admin.tailscale.com -> DNS):
- Domain `wagou.fr` uses custom nameserver `100.97.36.56` (Beelink's Tailscale IP)
- "Override local DNS" is **disabled** (so work network DNS still resolves corporate domains)

This means when Tailscale is connected:
- `*.wagou.fr` queries go to AdGuard Home via Tailscale -> resolves to `192.168.68.66` -> routed via subnet tunnel -> Traefik
- All other DNS queries use the local network's DNS (no conflict with corporate VPN/DNS)
- Ad blocking only applies to `wagou.fr` resolution when remote (not global)

The specific IP bindings in `adguardhome.nix` (`serverIP:53`, `tailscaleIP:53`, `127.0.0.1:53`) ensure AdGuard responds on LAN, Tailscale, and localhost. Port 53 on the host is mapped to port 5353 inside the container to avoid conflicts with Podman's aardvark-dns. The firewall explicitly allows port 53 on the `tailscale0` interface.

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
| Malicious URL Blocklist | `https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt` |
| OISD Big | `https://big.oisd.nl` |
| Liste FR - French ads | `https://adguardteam.github.io/HostlistsRegistry/assets/filter_16.txt` |

## Traefik routing

Traefik discovers services via the Docker/Podman provider. Each container declares Traefik labels to configure its router, TLS, and middlewares. All services share the `secure-headers@file` middleware (HSTS, X-Content-Type-Options, XSS protection).

Routing is determined by `Host()` rules matching the subdomain:

| Subdomain | Container | Container port | Notes |
|---|---|---|---|
| `vault.wagou.fr` | vaultwarden | 80 | `IP_HEADER = "X-Real-IP"` for audit logs |
| `pixel.wagou.fr` | immich-server | 2283 | - |
| `disk.wagou.fr` | seafile | 80 | SeaDoc + OIDC SSO via Authentik |
| `guard.wagou.fr` | adguard | 3000 | Web UI |
| `dash.wagou.fr` | homepage | 3000 | Dashboard (backgrounds via imgproxy) |
| `auth.wagou.fr` | authentik-server | 9000 | Identity provider / SSO (OIDC) |
| `assets.wagou.fr` | imgproxy | 8080 | Branding assets (logos, backgrounds, favicon) |
| `home.wagou.fr` | home-assistant | 8123 | - |
| `tape.wagou.fr` | jellyfin | 8096 | Intel VAAPI/QSV hardware transcoding |
| `dev.wagou.fr` | ttyd (host service) | 7681 | Routed via file provider dynamic config (not container labels) |
| `relay.wagou.fr` | webhook (host service) | 9000 | File provider dynamic config (not container labels) |
| `cabas.wagou.fr` | kitchenowl | 8080 | - |
| `apps.wagou.fr` | dokploy UI | 3001 | File provider dynamic config |
| `creneau.wagou.fr` | Dokploy app | 3000 | Forwarded to Dokploy Traefik at 127.0.0.1:9080 |
| `creneau-preview.wagou.fr` | Dokploy app | 3000 | Forwarded to Dokploy Traefik at 127.0.0.1:9080 |

## Dokploy — deploying apps

Dokploy is the PaaS layer for user-built applications. Access it at `https://apps.wagou.fr`.

### Adding a new Dokploy app

**1. In `variables.nix`** — add the subdomain to `appTunnelSubdomains`:
```nix
appTunnelSubdomains = [
  "creneau-preview"
  "creneau"
  "mynewapp"  # <-- add here
];
```
This auto-wires the Cloudflare Tunnel ingress, AdGuard DNS rewrite, and NixOS Traefik → Dokploy forward router.

**2. Run `nixos-rebuild switch`** to apply the routing changes.

**3. In Dokploy UI** — create the application:
- Source: **Docker image** → `ghcr.io/<owner>/<app>:latest` (pre-built in CI, never build on server)
- Domain: `mynewapp.wagou.fr` port `<app port>`
- Volume: **bind mount** `/var/lib/<appname>:/data` for persistence
- Env vars: configure per environment (preview vs prod)

### Preview vs production environments

Apps should have two Dokploy environments:
- **Preview** (`app-preview.wagou.fr`): `SEED_ON_INIT=true` or equivalent, uses `latest` image tag
- **Production** (`app.wagou.fr`): no seed, uses `latest` or pinned image tag, persistent bind mount

Key principle: **same image, different env vars** — never separate Dockerfiles or images per environment.

### Deployment best practices

- **Build in CI** (GitHub Actions), push to GHCR, Dokploy pulls the pre-built image
- **Docker image source** — not Git provider (avoids building on the server)
- **Bind mounts** for persistent data (not named volumes) — easier to backup and inspect
- **Persistent data** lives at `/var/lib/<appname>/` on the host
- **To reset an app's DB**: `ssh wagoulab`, `rm /var/lib/<appname>/<db file>`, redeploy in Dokploy UI
- **GHCR public images**: no registry registration needed in Dokploy — just use full image reference `ghcr.io/<owner>/<app>:<tag>`

## SSH access

> Also documented in `hosts/nixos/wagoulab/common/README.md` -> "SSH access" section.

SSH is hardened — key-only authentication, no passwords, no root login.

### SSH config on Mac (`~/.ssh/config`, managed by chezmoi)

```
Host wagoulab
    HostName 192.168.68.66
    User wagou
    IdentityFile ~/.ssh/id_ed25519_homeserver
    AddKeysToAgent yes
    UseKeychain yes
```

Connect with: `ssh wagoulab`

### Authorized key

The homeserver SSH public key is declared in `hosts/nixos/configuration.nix` under `users.users.wagou.openssh.authorizedKeys.keys`. This is the `id_ed25519_homeserver` key (separate from the work SSH key for identity separation).

## Adding a new NixOS service

This is for **infrastructure/homelab services** managed by NixOS (Podman/quadlet-nix). For user-built apps, use Dokploy instead (see section above).

### Step 1 — Create the service dir

Create `common/services/<newservice>/default.nix` using the shared helper (don't hand-write Traefik labels):

```nix
{ config, host, ... }:

let
  ws = import ../lib/web-service.nix { inherit config host; };
  svc = ws.mkWebService {
    name = "newservice";
    subdomain = "newservice";
    image = "org/newservice:latest";
    port = 80;
    volumes = [ "/var/lib/newservice:/data" ];
    environmentFiles = [ config.sops.templates."newservice.env".path ];
    dataDirs = [ "/var/lib/newservice" ];
  };
in
{
  virtualisation.quadlet.containers.newservice.containerConfig = svc.containerConfig;
  systemd.tmpfiles.rules = svc.tmpfilesRules;
}
```

The helper sets the `proxy` network, `noNewPrivileges`, and the Traefik labels (`Host()` rule, `websecure`, `secure-headers@file`). For Postgres/Valkey sidecars use `ws.mkPostgres` / `ws.mkValkey` (see `immich/` or `omnigent/`). Variants (`exposeViaTraefik = false`, `networks = [ "host" ]`, `devices`, `healthCmd`, …) are documented in `lib/web-service.nix`.

### Step 2 — Import it

Add `./<newservice>` to the imports in `common/services/default.nix`.

### Step 3 — Add subdomain to variables

Add the subdomain to `serviceTunnelSubdomains` in **both** `hosts/nixos/wagoulab/prime/variables.nix` and `hosts/nixos/wagoulab/clone/variables.nix` (keep the lists mirrored):

```nix
serviceTunnelSubdomains = [
  "vault" "pixel" "dash" "guard" "home" "tape"
  "dev" "apps" "relay" "cabas" "auth" "disk" "assets"
  "newservice" # <-- add your new subdomain here (both files)
];
```

This automatically wires up:
- DNS rewrite in AdGuard Home (local HTTPS bypass)
- Tunnel ingress rule in cloudflared (remote access)
- NixOS Traefik router pointing directly to the Podman container

### Step 4 — Add secrets (if needed)

Create `common/services/<newservice>/secrets.yaml` (via `sops`) and declare each key in the service module with `sopsFile = ./secrets.yaml`:

```nix
sops.secrets.newservice-secret = {
  sopsFile = ./secrets.yaml;
  mode = "0400";
};

# If the service needs KEY=VALUE env format:
sops.templates."newservice.env" = {
  content = "SECRET=${config.sops.placeholder.newservice-secret}\n";
};
```

(`.sops.yaml` already covers `common/services/*/secrets.yaml` — no new rule needed.)

### Step 5 — Add Cloudflare DNS route

Run `cloudflared tunnel route dns wagou-prime newservice.wagou.fr` once from your Mac (requires `cert.pem` from `cloudflared login`).

### Step 6 — Deploy

```bash
git add -A && git commit -m "feat: add newservice" && git push
sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagou-prime --refresh
```

NOTE: The clone disables all quadlet containers by default (`clone/services-disabled.nix`) — rebuilding it picks up the new service definition but leaves it idle until failover. Rebuild both to keep them in sync.

## Troubleshooting

> Full troubleshooting guide: see `hosts/nixos/wagoulab/common/README.md` -> "Troubleshooting" section.

### Seafile branding/config not applied

`seahub_settings.py` and the Catppuccin `custom.css` are seeded automatically by an `ExecStartPre` step on every container start (Seafile only reads them from inside its self-initialized data dir, so they can't be plain mounts). The seed is skipped until first init has created the conf dir. No manual step.

### Seafile fails to start ("Failed to load environment files")

sops-nix decrypts secrets during the NixOS activation script (before services start). If Seafile can't find its environment file, check:
1. `sudo ls -la /run/secrets/rendered/seafile.env` — should exist
2. `journalctl -u seafile --no-pager | tail -20` — check for specific error
3. sops-nix does NOT use a systemd service — do NOT add `after = [ "sops-nix.service" ]`

### Ghostty terminal error when SSHing

If you see `'xterm-ghostty': unknown terminal type`, the `ghostty.terminfo` package is installed on the server. If it happens again, run `export TERM=xterm-256color` as a workaround.

### Cloudflare Tunnel not connecting

1. `systemctl status cloudflared` (quadlet-nix container unit)
2. `journalctl -u cloudflared --no-pager -f`
3. Common error: "couldn't read tunnel credentials" — check `cloudflare-credentials-prime` / `cloudflare-credentials-clone` sops secrets and credentials-file path

### 502 Bad Gateway from Cloudflare

Tunnel connected but service not responding:
1. Is Traefik running? `systemctl status traefik`
2. Is the service running? `systemctl status <service>`
3. Check Traefik logs: `journalctl -u traefik --no-pager -f`
4. Ensure the container is on the `proxy` network and has correct Traefik labels

### DNS not resolving locally

1. `scutil --dns | grep nameserver` — should show `192.168.68.66`
2. Force DHCP renewal: `sudo ipconfig set en0 DHCP`
3. Test directly: `nslookup vault.wagou.fr 192.168.68.66`
4. Do NOT use `.local` domains — macOS intercepts them for mDNS. Use `*.wagou.fr` with AdGuard Home rewrites.

### "Internet not available" on macOS

If IPv6 is enabled on the Deco and the Beelink's IPv6 DNS is configured, this should not happen. If it does, check if `captive.apple.com` is being blocked in AdGuard Home query log. If so, add an allowlist rule.

### Can't decrypt sops secrets (on Mac)

Ensure `~/.config/sops/age/keys.txt` exists and contains your age private key. If not, regenerate with `age-keygen -o ~/.config/sops/age/keys.txt` and update the public key in `.sops.yaml`, then re-encrypt with `sops updatekeys hosts/nixos/wagoulab/common/secrets.yaml` (or the relevant `services/<name>/secrets.yaml`).

## Key commands

| Action | Command |
|---|---|
| SSH into primary | `ssh wagoulab` |
| SSH into backup | `ssh wagou-clone` |
| Rebuild primary from GitHub | `sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagou-prime --refresh` |
| Rebuild backup from GitHub | `sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagou-clone --refresh` |
| Check service status | `systemctl status <service>` |
| View service logs | `journalctl -u <service> --no-pager -f` |
| Stop/start a service | `sudo systemctl stop/start <service>` |
| Edit shared secrets | `sops hosts/nixos/wagoulab/common/secrets.yaml` |
| Edit service secrets | `sops hosts/nixos/wagoulab/common/services/<name>/secrets.yaml` |
| Test build | `nix eval .#nixosConfigurations.wagou-prime.config.system.build.toplevel.drvPath` |
| List restic snapshots | `restic -r /var/backup/restic snapshots` |
| Restore from backup | `restic -r /var/backup/restic restore latest --target /` |
| Switch DNS to backup | `for sub in dash vault pixel guard home tape dev relay cabas auth disk docs pantone assets mailbox crawl; do TUNNEL_FORCE_PROVISIONING_DNS=true cloudflared tunnel route dns wagou-clone "$sub.wagou.fr"; done` |
| Switch DNS to primary | `for sub in dash vault pixel guard home tape dev relay cabas auth disk docs pantone assets mailbox crawl; do TUNNEL_FORCE_PROVISIONING_DNS=true cloudflared tunnel route dns wagou-prime "$sub.wagou.fr"; done` |

## Important rules

- Each service gets its own dir in `common/services/<name>/` (`default.nix` + `secrets.yaml`) — one service per dir, built with `lib/web-service.nix`
- All **NixOS-managed services** run as Podman containers via quadlet-nix on the `proxy` network (helper sets labels, `noNewPrivileges`, tmpfiles)
- **User-built apps** go through Dokploy — do NOT add app containers to NixOS config
- To expose a new app subdomain, add it to `appTunnelSubdomains` in **both** `prime/variables.nix` and `clone/variables.nix` (not `serviceTunnelSubdomains`); raw TCP/UDP services use `dnsOnlySubdomains`
- Traefik discovers services via Docker/Podman labels (set by the helper) — no manual routing config needed
- Shared secrets go in `hosts/nixos/wagoulab/common/secrets.yaml`, per-service secrets in `common/services/<name>/secrets.yaml` (encrypted with sops, `sopsFile = ./secrets.yaml`) — NEVER as plain files on the server
- AdGuard Home DNS rewrites need `enabled = true` — defaults to `false`
- Traefik serves HTTPS with Let's Encrypt wildcard cert
- Cloudflare Tunnel routes use HTTPS to `traefik:443` (container network) with `noTLSVerify = true`
- AdGuard Home DNS rewrites for `*.wagou.fr` point to the local IP so LAN devices bypass Cloudflare
- `system.stateVersion = "25.05"` — never change this
- `hardware.nix` was generated by `nixos-generate-config` — only regenerate if hardware changes
- Always test builds before pushing: `nix eval .#nixosConfigurations.wagou-prime.config.system.build.toplevel.drvPath`
- SSH uses a dedicated key (`id_ed25519_homeserver`), separate from work SSH key
- Both machines share `common/` via the flake — changes in `common/services/` apply to both wagou-prime and wagou-clone (clone stays idle via `services-disabled.nix` until failover)
- Machine-specific settings go in `hosts/nixos/wagoulab/{prime,clone}/variables.nix` (hostname, IP, tunnel ID, NIC)
- After deploying changes, rebuild **both** machines to keep them in sync
