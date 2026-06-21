---
name: homeserver
description: Manage the NixOS homeserver (wagoulab) — add services, configure secrets, DNS rewrites, Cloudflare Tunnel routes, Traefik reverse proxy, security hardening, and troubleshoot the Beelink EQI13.
---

## Overview

The homeserver (wagoulab) is a Beelink EQI13 running NixOS (x86_64-linux, 32 GB RAM, 512 GB NVMe) at IP `192.168.68.65`. It serves as a self-hosted service platform with network-wide ad blocking and secure remote access via Cloudflare Tunnel and Tailscale.

Domain: `wagou.fr` (registered at OVH, DNS managed by Cloudflare)

## Architecture

```
Remote access:  Browser -> Cloudflare (HTTPS) -> Tunnel (encrypted) -> Traefik (HTTPS :443) -> Service/App
Remote access:  SSH/LAN -> Tailscale (WireGuard) -> Beelink (subnet router) -> 192.168.68.0/24
Remote access:  Browser -> Tailscale (split DNS) -> AdGuard Home -> 192.168.68.65 -> Traefik -> Service/App
Local access:   Browser -> AdGuard Home (*.wagou.fr -> 192.168.68.65) -> Traefik (HTTPS :443) -> Service/App
```

### Services vs Apps — two-tier deployment model

The homeserver uses a **two-tier deployment model**:

| Tier | What | Managed by | Container runtime | Config location |
|---|---|---|---|---|
| **Services** | Infrastructure & homelab services (Vaultwarden, Immich, Jellyfin, etc.) | NixOS / quadlet-nix | Podman | `hosts/nixos/wagoulab/services/*.nix` |
| **Apps** | User-built applications (creneau, future apps) | Dokploy | Docker (Swarm) | Dokploy UI + app repo `docker-compose.yml` |

**Services** are declared in the wagounix flake and deployed via `nixos-rebuild switch`. They run as Podman containers on the shared `proxy` network, discovered by Traefik via Podman labels.

**Apps** are deployed via **Dokploy** (`apps.wagou.fr`), a self-hosted PaaS running as a Docker Swarm stack on the same server. Dokploy manages container lifecycle, rolling deploys, environment variables, and volumes. Apps use pre-built Docker images from GHCR (built by CI — never built on the server).

### Routing architecture

```
serviceTunnelSubdomains  →  NixOS Traefik → Podman container (direct)
appTunnelSubdomains      →  NixOS Traefik → Dokploy Traefik (127.0.0.1:9080) → Docker container
```

Both lists are defined in `hosts/nixos/wagoulab/variables.nix`. Adding a subdomain to either list automatically wires up:
- Cloudflare Tunnel ingress rule
- AdGuard Home DNS rewrite
- NixOS Traefik router (either direct or forwarded to Dokploy)

### Container runtimes

- **Podman** (quadlet-nix): used for NixOS-managed services. Containers on the `proxy` Podman network. Traefik listens on the Podman socket (`/run/podman/podman.sock`) for label discovery.
- **Docker Swarm** (Dokploy): used for user apps. Containers on the `apps` Docker overlay network. Dokploy has its own Traefik instance on port 9080 (internal) that NixOS Traefik forwards app subdomains to.

Tailscale runs as a native NixOS service (not a container) and acts as a subnet router, advertising the home LAN (`192.168.68.0/24`). This provides remote SSH access and access to any LAN device from anywhere. The Beelink's Tailscale IP is `100.68.157.70`.

IMPORTANT: AdGuard Home DNS rewrites for `*.wagou.fr` point to the local IP so LAN devices bypass Cloudflare and connect directly to Traefik HTTPS.
IMPORTANT: AdGuard Home DNS is published on specific IPs (`192.168.68.65`, Tailscale IP, `127.0.0.1`) on port 53, mapped to container port 5353. This avoids conflicts with Podman's aardvark-dns which binds port 53 on bridge gateway IPs. The firewall restricts access to known interfaces only.

## Current services

### NixOS-managed services (Podman / quadlet-nix)

| Service | NixOS config | Container port | Remote URL |
|---|---|---|---|
| Vaultwarden | `services/vaultwarden.nix` | 80 (Podman network) | `https://vault.wagou.fr` |
| Seafile | `services/seafile/` | 80 (Podman network) | `https://disk.wagou.fr` |
| Immich | `services/immich.nix` | 2283 (Podman network) | `https://pixel.wagou.fr` |
| Homepage | `services/homepage/` | 3000 (Podman network) | `https://dash.wagou.fr` |
| Home Assistant | `services/home-assistant.nix` | 8123 (Podman network) | `https://home.wagou.fr` |
| Jellyfin | `services/jellyfin.nix` | 8096 (Podman network) | `https://tape.wagou.fr` |
| Traefik | `services/traefik.nix` | 80, 443 (published to host) | - |
| AdGuard Home | `services/adguardhome.nix` | 5353 (mapped to host:53 on LAN/Tailscale/lo), 3000 (web UI) | `https://guard.wagou.fr` |
| Cloudflare Tunnel | `services/cloudflared.nix` | Outbound only | - |
| Tailscale | `services/tailscale.nix` | Native NixOS service (subnet router) | - |
| Fail2ban | `services/fail2ban.nix` | - | - |
| ttyd | `services/ttyd.nix` | 7681 (native systemd service) | `https://dev.wagou.fr` |
| rbw | `services/rbw.nix` | - (custom pinentry script) | - |
| Webhook | `services/webhook.nix` | 9000 (host service, native) | `https://relay.wagou.fr` |
| Renovate | `services/renovate.nix` | - (systemd oneshot + timer) | - |
| KitchenOwl | `services/kitchenowl.nix` | 8080 (Podman network) | `https://cabas.wagou.fr` |
| Authentik | `services/authentik/` | 9000 (Podman network) | `https://auth.wagou.fr` |
| Branding (imgproxy) | `services/branding.nix` | 8080 (Podman network) | `https://assets.wagou.fr` |
| Dokploy | `services/dokploy.nix` | 3001 (UI, published to 127.0.0.1), 9080 (Traefik, internal) | `https://apps.wagou.fr` |

### Dokploy-managed apps (Docker Swarm)

| App | Image | Remote URL | Notes |
|---|---|---|---|
| Creneau (prod) | `ghcr.io/pierrewagou/creneau:latest` | `https://creneau.wagou.fr` | Persistent bind mount `/var/lib/creneau:/app/data`, no `SEED_ON_INIT` |
| Creneau (preview) | `ghcr.io/pierrewagou/creneau:latest` | `https://creneau-preview.wagou.fr` | `SEED_ON_INIT=true`, seeded with fake data on first boot |

## Files

### Host-level config: `hosts/nixos/wagoulab/`

| File | Purpose |
|---|---|
| `default.nix` | Imports hardware.nix and services/ |
| `variables.nix` | Host variables: `username`, `hostname`, `domain`, `serverIP`, `tailscaleIP`, `networkInterface`, `lanSubnet`, `renderGroupGid`, `timezone`, `acmeEmail`, `adminEmail`, `cloudflareAccountId`, `cloudflareTunnelId`, `serviceTunnelSubdomains` (NixOS-managed), `appTunnelSubdomains` (Dokploy-managed), `valkeyImage`, `podmanCIDRs`, `ports`, `latitude`, `longitude` |
| `hardware.nix` | Auto-generated hardware config from `nixos-generate-config` (boot, filesystems, kernel modules, Intel microcode) |

### Services: `hosts/nixos/wagoulab/services/`

| File | Purpose |
|---|---|
| `default.nix` | Imports all service modules |
| `podman.nix` | Podman runtime, quadlet-nix shared `proxy` network |
| `secrets.nix` | sops-nix secret declarations and templates |
| `traefik.nix` | Traefik reverse proxy container (Let's Encrypt, HSTS headers, Cloudflare trusted IPs) |
| `vaultwarden.nix` | Password manager container |
| `seafile/` | File sync & sharing (Seafile MC + SeaDoc + MariaDB + Redis, OIDC SSO via Authentik) |
| `immich.nix` | Photo management (server, ML, PostgreSQL, Redis — 4 containers + internal network) |
| `adguardhome.nix` | DNS server container, ad blocking, blocklists, local DNS rewrites |
| `cloudflared.nix` | Cloudflare Tunnel container |
| `tailscale.nix` | Tailscale VPN (native NixOS service, subnet router for `192.168.68.0/24`) |
| `homepage/` | Homepage dashboard container (Catppuccin theme via branding module, service widgets, imgproxy backgrounds) |
| `authentik/` | Identity provider / SSO — OIDC (server, worker, PostgreSQL, Redis) |
| `branding.nix` | Shared Catppuccin theme + imgproxy assets server (logos, backgrounds, favicon, CSS) |
| `branding-assets/` | Source images and favicon served via imgproxy (`assets.wagou.fr`) |
| `home-assistant.nix` | Home automation container |
| `jellyfin.nix` | Media server container with Intel hardware transcoding |
| `fail2ban.nix` | Brute force protection |
| `firewall.nix` | Firewall rules (ports 22, 53, 80, 443) |
| `ttyd.nix` | Web terminal for remote dev access (Catppuccin theme, Nerd Font, native systemd service) |
| `rbw.nix` | Custom pinentry script for rbw (reads master password from sops secret) |
| `dokploy.nix` | Dokploy PaaS — Docker Swarm stack (postgres, redis, traefik, ui), published at `apps.wagou.fr` |
| `webhook.nix` | GitHub webhook receiver (triggers rebuilds + Renovate) |
| `renovate.nix` | Dependency update bot (systemd oneshot + timer + token script) |
| `kitchenowl.nix` | Recipes & grocery lists container |

### Platform-level NixOS config: `hosts/nixos/`

| File | Purpose |
|---|---|
| `default.nix` | Imports `configuration.nix` and `packages.nix` |
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
| `rbw-master-password` | `rbw.nix` | Raw secret file (owner: wagou, mode: 0400) |
| `github-webhook-secret` | `webhook.nix` | Via sops template `webhook.env` |
| `renovate-github-app-id` | `renovate.nix` | Raw secret file (token generation script) |
| `renovate-github-app-key` | `renovate.nix` | Raw secret file (base64-encoded PEM) |
| `renovate-installation-id` | `renovate.nix` | Raw secret file (token generation script) |
| `kitchenowl-jwt-secret` | `kitchenowl.nix` | Via sops template `kitchenowl.env` |
| `kitchenowl-oidc-client-secret` | `kitchenowl.nix` | OIDC client secret (Authentik SSO), via `kitchenowl.env` |
| `authentik-secret-key` | `authentik.nix` | Via sops template `authentik.env` |
| `authentik-postgres-password` | `authentik.nix` | Via `authentik.env` + `authentik-postgres.env` |
| `seafile-mysql-root-password` | `seafile.nix` | Via `seafile.env` + `seafile-db.env` |
| `seafile-mysql-password` | `seafile.nix` | Via sops template `seafile.env` |
| `seafile-jwt-key` | `seafile.nix` | Via sops template `seafile.env` |
| `seafile-secret-key` | `seafile.nix` | Via `seahub_settings.py` template |
| `seafile-oauth-client-secret` | `seafile.nix` | OIDC client secret (Authentik SSO), via `seahub_settings.py` |

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
- "Override local DNS" is **disabled** (so work network DNS still resolves corporate domains)

This means when Tailscale is connected:
- `*.wagou.fr` queries go to AdGuard Home via Tailscale -> resolves to `192.168.68.65` -> routed via subnet tunnel -> Traefik
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

The homeserver SSH public key is declared in `hosts/nixos/configuration.nix` under `users.users.wagou.openssh.authorizedKeys.keys`. This is the `id_ed25519_homeserver` key (separate from the work SSH key for identity separation).

## Adding a new NixOS service

This is for **infrastructure/homelab services** managed by NixOS (Podman/quadlet-nix). For user-built apps, use Dokploy instead (see section above).

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

Add the subdomain to `serviceTunnelSubdomains` in `hosts/nixos/wagoulab/variables.nix`:

```nix
serviceTunnelSubdomains = [
  "vault" "pixel" "dash" "guard" "home" "tape"
  "dev" "apps" "relay" "cabas" "auth" "disk" "assets"
  "newservice" # <-- add your new subdomain here
];
```

This automatically wires up:
- DNS rewrite in AdGuard Home (local HTTPS bypass)
- Tunnel ingress rule in cloudflared (remote access)
- NixOS Traefik router pointing directly to the Podman container

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

### Seafile branding/config not applied

`seahub_settings.py` and the Catppuccin `custom.css` are deployed by the manual idempotent `seafile-deploy` script (Seafile generates its config on first run, so it can't be fully declarative). After the first start, run `sudo seafile-deploy` to copy the rendered config + CSS into the container and restart seahub.

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
- All **NixOS-managed services** run as Podman containers via quadlet-nix on the `proxy` network
- **User-built apps** go through Dokploy — do NOT add app containers to NixOS config
- To expose a new app subdomain, add it to `appTunnelSubdomains` in `variables.nix` (not `serviceTunnelSubdomains`)
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
