# Wagoulab

NixOS on a Beelink EQI13 (x86_64-linux, 32 GB RAM, 512 GB NVMe) running self-hosted services with network-wide ad blocking and secure remote access.

## Architecture

```
Remote (phone/laptop outside home)
  ── https://*.wagou.fr ──▶ Cloudflare (valid TLS) ──▶ Tunnel (encrypted)
                                                             │
Local (home network)                                         │
  ── https://*.wagou.fr ──▶ AdGuard Home (DNS rewrite) ──────────────┤
                                                             ▼
                                                        Traefik (HTTPS :443)
                                                             │
                                              ┌──────────────┼──────────────┐
                                              ▼              ▼              ▼
                                        Vaultwarden    OpenCloud        Immich
                                          (:80)         (:9200)        (:2283)
```

All services run as Podman containers managed by quadlet-nix. They communicate over a shared `proxy` Podman network — no ports are published to the host except Traefik (80/443) and AdGuard Home (53). Traefik serves HTTPS with Let's Encrypt wildcard certificates (DNS-01 challenge via Cloudflare). The Cloudflare Tunnel connects to Traefik over HTTPS (container-to-container). On the local network, AdGuard Home rewrites `*.wagou.fr` to the Beelink's IP, bypassing Cloudflare.

## Services

| Service | Purpose | Remote URL | Container port |
|---|---|---|---|
| **Vaultwarden** | Password manager (Bitwarden-compatible) | `https://vault.wagou.fr` | 80 |
| **OpenCloud** | File sync & sharing (ownCloud-compatible) | `https://cloud.wagou.fr` | 9200 |
| **Immich** | Photo management (Google Photos replacement) | `https://pixel.wagou.fr` | 2283 |
| **Homepage** | Dashboard (Catppuccin Mocha theme) | `https://dash.wagou.fr` | 3000 |
| **Home Assistant** | Home automation | `https://home.wagou.fr` | 8123 |
| **Jellyfin** | Media server (hardware transcoding) | `https://tape.wagou.fr` | 8096 |
| **Traefik** | Reverse proxy + HTTPS termination | - | 80, 443 |
| **AdGuard Home** | DNS server + ad blocker | `https://guard.wagou.fr` | 53, 3000 |
| **Cloudflare Tunnel** | Secure remote access (web services) | - | Outbound only |
| **Tailscale** | VPN + subnet router (SSH, LAN access) | - | Native NixOS service |
| **Fail2ban** | Brute force protection | - | - |

## Hardware

| Spec | Value |
|---|---|
| Machine | Beelink EQI13 |
| CPU | Intel (x86_64) |
| RAM | 32 GB |
| Storage | 512 GB NVMe |
| OS | NixOS 25.05 |
| IP | 192.168.68.65 |

### Disk partitions

| Partition | Type | Size | Mount |
|---|---|---|---|
| `nvme0n1p1` | FAT32 (EFI) | 512 MB | `/boot` |
| `nvme0n1p2` | Swap | 8 GB | swap |
| `nvme0n1p3` | ext4 | ~457 GB | `/` |

## Files

```
hosts/nixos/wagoulab/
├── default.nix              # Imports hardware.nix and services/
├── variables.nix            # Host variables (username, homeDir, hostname, domain, serverIP, timezone, acmeEmail, cloudflare IDs, tunnel subdomains)
├── hardware.nix             # Auto-generated hardware config (boot, filesystems, kernel modules)
├── secrets.yaml             # sops-encrypted secrets (age encryption)
└── services/
    ├── default.nix          # Imports all service modules + system packages
    ├── podman.nix           # Podman runtime, quadlet-nix shared proxy network
    ├── secrets.nix          # sops-nix secret declarations and templates
    ├── traefik.nix          # Reverse proxy (Traefik container with Let's Encrypt)
    ├── vaultwarden.nix      # Password manager
    ├── opencloud.nix        # File sync & sharing
    ├── immich.nix           # Photo management
    ├── home-assistant.nix   # Home automation
    ├── jellyfin.nix         # Media server
    ├── adguardhome.nix      # DNS server + ad blocker
    ├── cloudflared.nix      # Cloudflare Tunnel
    ├── tailscale.nix        # Tailscale VPN (subnet router for LAN access)
    ├── homepage.nix         # Homepage dashboard
    ├── homepage-images/     # Background images and favicon for Homepage dashboard
    ├── fail2ban.nix         # Brute force protection
    └── firewall.nix         # Firewall rules (ports 22, 53, 80, 443)
```

Platform-level config at `hosts/nixos/`:

| File | Purpose |
|---|---|
| `configuration.nix` | SSH (hardened), user account, timezone, auto-updates, firewall enable |

## Security

| Layer | Protection |
|---|---|
| **Network** | No open ports on router, all traffic through Cloudflare Tunnel |
| **TLS** | Let's Encrypt wildcard certificate (DNS-01 via Cloudflare), served by Traefik |
| **SSH** | Key-only authentication, password auth disabled, root login disabled |
| **Fail2ban** | Bans IPs after 5 failed SSH attempts for 1 hour |
| **Firewall** | Only ports 22 (SSH), 53 (DNS), 80 (HTTP redirect), 443 (HTTPS) open |
| **DNS** | AdGuard Home with DNS-over-HTTPS upstream (Cloudflare + Google) |
| **Secrets** | sops-nix with age encryption, decrypted to RAM only (`/run/secrets/`) |
| **Vaultwarden** | Signups disabled, admin panel protected with token |
| **Rate limiting** | Cloudflare WAF rate limiting on all `*.wagou.fr` |
| **Auto-updates** | Daily rebuild at 4:00 AM from flake |
| **Service isolation** | All services on Podman internal network, behind Traefik reverse proxy |

## Secrets (sops-nix)

Secrets are encrypted with age in `secrets.yaml` (at the homeserver host level) and decrypted at activation time on the Beelink.

| Secret | Used by | Runtime path |
|---|---|---|
| `cloudflare-credentials` | Cloudflare Tunnel (credentials file) | `/run/secrets/cloudflare-credentials` |
| `opencloud-admin-password` | OpenCloud (via sops template) | `/run/secrets/rendered/opencloud.env` |
| `vaultwarden-admin-token` | Vaultwarden (via sops template) | `/run/secrets/rendered/vaultwarden.env` |
| `immich-db-username` | Immich + PostgreSQL (via sops template) | `/run/secrets/rendered/immich.env` |
| `immich-db-password` | Immich + PostgreSQL (via sops template) | `/run/secrets/rendered/immich-postgres.env` |
| `wagou-password-hash` | User password | `/run/secrets/wagou-password-hash` |
| `root-password-hash` | Root password | `/run/secrets/root-password-hash` |
| `immich-api-key` | Homepage widget (via sops template) | `/run/secrets/rendered/homepage.env` |
| `adguard-password` | Homepage widget (via sops template) | `/run/secrets/rendered/homepage.env` |
| `cloudflare-tunnel-token` | Homepage widget (via sops template) | `/run/secrets/rendered/homepage.env` |
| `cloudflare-dns-token` | ACME DNS-01 challenge (via sops template) | `/run/secrets/rendered/traefik.env` |
| `jellyfin-api-key` | Homepage widget (via sops template) | `/run/secrets/rendered/homepage.env` |

### Editing secrets

```bash
sops hosts/nixos/wagoulab/secrets.yaml
```

Or in Neovim (sops.nvim auto-decrypts):

```bash
nvim hosts/nixos/wagoulab/secrets.yaml
```

### Adding a new secret

1. Edit `secrets.yaml` with `sops` — add a new key-value pair
2. Declare it in `services/secrets.nix` under `sops.secrets`
3. If it needs `KEY=VALUE` format, create a `sops.templates` entry
4. Reference `config.sops.secrets.<name>.path` or `config.sops.templates.<name>.path` in the service config

### Encryption keys

| Key | Purpose | Location |
|---|---|---|
| Admin age key (public) | Encrypt secrets from your Mac | `.sops.yaml` |
| Admin age key (private) | Decrypt secrets for editing | `~/.config/sops/age/keys.txt` (Mac only) |
| Homeserver SSH host key | Decrypt secrets at activation | `/etc/ssh/ssh_host_ed25519_key` (Beelink) |

## Network setup

### Router configuration (TP-Link Deco)

| Setting | Value |
|---|---|
| DHCP DNS server (IPv4) | `192.168.68.65` (Beelink) |
| Internet Connection DNS (IPv4) | `192.168.68.65` (primary), `1.1.1.1` (fallback) |
| Internet Connection DNS (IPv6) | Beelink's IPv6 (primary), `2606:4700:4700::1111` (fallback) |
| IPv6 | Enabled |
| DHCP reservation | Beelink MAC -> `192.168.68.65` |

### DNS resolution flow

| Query | Resolution |
|---|---|
| `*.wagou.fr` (remote devices) | Cloudflare DNS -> Cloudflare Tunnel -> Beelink |
| `*.wagou.fr` (local devices) | AdGuard Home rewrite -> `192.168.68.65` (direct HTTPS, bypasses Cloudflare) |
| Ad/tracker domains | AdGuard Home -> blocked (`0.0.0.0`) |
| Everything else | AdGuard Home -> Cloudflare/Google DoH -> Internet |

### Domain

| Component | Provider |
|---|---|
| Registrar | OVH (`wagou.fr`) |
| DNS | Cloudflare (nameservers pointed from OVH) |
| TLS certificates | Let's Encrypt (wildcard via DNS-01, Cloudflare DNS) |
| Email | OVH Zimbra (MX records in Cloudflare) |
| Tunnel | Cloudflare Zero Trust |

## Adding a new service

1. **Create** `services/<newservice>.nix` with a Podman container definition:
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
2. **Import** it in `services/default.nix`
3. **Add subdomain** to `tunnelSubdomains` in `hosts/nixos/wagoulab/variables.nix`. This automatically wires up:
   - DNS rewrite in AdGuard Home (local HTTPS bypass)
   - Tunnel ingress rule in cloudflared (remote access)
4. **Add secrets** if needed in `services/secrets.nix`
5. **Add DNS CNAME record**: Run `cloudflared tunnel route dns wagoulab newservice.wagou.fr` once from a machine with `cert.pem` (your Mac after `cloudflared login`).
6. **Push and rebuild**:
   ```bash
   git add -A && git commit -m "feat: add newservice" && git push
   sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagoulab --refresh
   ```

## Quick reference

| Action | Command |
|---|---|
| SSH into server | `ssh wagoulab` |
| Rebuild from GitHub | `sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#wagoulab --refresh` |
| Check service status | `systemctl status <service>` |
| View service logs | `journalctl -u <service> --no-pager -f` |
| Stop/start a service | `sudo systemctl stop/start <service>` |
| Edit secrets | `sops hosts/nixos/wagoulab/secrets.yaml` |
| Test build locally | `nix eval .#nixosConfigurations.wagoulab.config.system.build.toplevel.drvPath` |
| AdGuard Home dashboard | `https://guard.wagou.fr` |
| Homepage dashboard | `https://dash.wagou.fr` |
| Vaultwarden | `https://vault.wagou.fr` |
| OpenCloud | `https://cloud.wagou.fr` |
| Immich | `https://pixel.wagou.fr` |
| Home Assistant | `https://home.wagou.fr` |
| Jellyfin | `https://tape.wagou.fr` |

## Planned services

| Service | Purpose | Status |
|---|---|---|
| Ollama | Local LLM inference | Planned |
| Backups | borgbackup/restic to external drive or cloud | Planned |
| Monitoring | Uptime Kuma or similar | Planned |
