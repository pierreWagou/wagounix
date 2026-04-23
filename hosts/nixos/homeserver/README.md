# Homeserver

NixOS on a Beelink EQI13 (x86_64-linux, 32 GB RAM, 512 GB NVMe) running self-hosted services with network-wide ad blocking and secure remote access.

## Architecture

```
Remote (phone/laptop outside home)
  ── https://*.wagou.fr ──▶ Cloudflare (valid TLS) ──▶ Tunnel (encrypted)
                                                             │
Local (home network)                                         │
  ── *.wagou.fr ──▶ AdGuard Home (DNS rewrite) ──────────────┤
                                                             ▼
                                                       Caddy (HTTP :80)
                                                             │
                                              ┌──────────────┼──────────────┐
                                              ▼              ▼              ▼
                                        Vaultwarden    OpenCloud        Immich
                                         (:8222)        (:9200)        (:2283)
```

All `*.wagou.fr` traffic goes through Cloudflare (HTTPS everywhere) when remote. On the local network, AdGuard Home rewrites `*.wagou.fr` to the Beelink's IP, bypassing Cloudflare. Caddy serves HTTP only — Cloudflare handles public TLS.

## Services

| Service | Purpose | Remote URL | Port |
|---|---|---|---|
| **Vaultwarden** | Password manager (Bitwarden-compatible) | `https://vault.wagou.fr` | 8222 |
| **OpenCloud** | File sync & sharing (ownCloud-compatible) | `https://cloud.wagou.fr` | 9200 |
| **Immich** | Photo management (Google Photos replacement) | `https://pixel.wagou.fr` | 2283 |
| **Homepage** | Dashboard (Catppuccin Mocha theme) | `https://home.wagou.fr` | 8082 |
| **Caddy** | Reverse proxy | - | 80 |
| **AdGuard Home** | DNS server + ad blocker | - | 53, 3000 |
| **Cloudflare Tunnel** | Secure remote access | - | Outbound only |
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
hosts/nixos/homeserver/
├── default.nix              # Imports hardware.nix and services/
├── variables.nix            # Host variables (username, homeDir, hostname, domain, serverIP)
├── hardware.nix             # Auto-generated hardware config (boot, filesystems, kernel modules)
├── secrets.yaml             # sops-encrypted secrets (age encryption)
└── services/
    ├── default.nix          # Imports all service modules + system packages
    ├── secrets.nix          # sops-nix secret declarations and templates
    ├── vaultwarden.nix      # Password manager
    ├── opencloud.nix        # File sync & sharing
    ├── immich.nix           # Photo management
    ├── caddy.nix            # Reverse proxy (all virtual hosts)
    ├── adguardhome.nix      # DNS server + ad blocker
    ├── cloudflared.nix      # Cloudflare Tunnel
    ├── homepage.nix         # Homepage dashboard
    ├── homepage-images/     # Background images for Homepage dashboard
    ├── fail2ban.nix         # Brute force protection
    └── firewall.nix         # Firewall rules (ports 22, 80)
```

Platform-level config at `hosts/nixos/`:

| File | Purpose |
|---|---|
| `configuration.nix` | SSH (hardened), Docker, user account, timezone, auto-updates |

## Security

| Layer | Protection |
|---|---|
| **Network** | No open ports on router, all traffic through Cloudflare Tunnel |
| **TLS** | Cloudflare handles HTTPS with valid certificates |
| **SSH** | Key-only authentication, password auth disabled, root login disabled |
| **Fail2ban** | Bans IPs after 5 failed SSH attempts for 1 hour |
| **Firewall** | Only ports 80 (HTTP), 53 (DNS), 22 (SSH), 3000 (AdGuard web UI) open |
| **DNS** | AdGuard Home with DNS-over-HTTPS upstream (Cloudflare + Google) |
| **Secrets** | sops-nix with age encryption, decrypted to RAM only (`/run/secrets/`) |
| **Vaultwarden** | Signups disabled, admin panel protected with token |
| **Rate limiting** | Cloudflare WAF rate limiting on all `*.wagou.fr` |
| **Auto-updates** | Daily rebuild at 4:00 AM from flake |
| **Service binding** | All services on `127.0.0.1` (localhost only), behind Caddy |

## Secrets (sops-nix)

Secrets are encrypted with age in `secrets.yaml` (at the homeserver host level) and decrypted at activation time on the Beelink.

| Secret | Used by | Runtime path |
|---|---|---|
| `cloudflared-token` | Cloudflare Tunnel | `/run/secrets/cloudflared-token` |
| `opencloud-admin-password` | OpenCloud (via sops template) | `/run/secrets/rendered/opencloud.env` |
| `vaultwarden-admin-token` | Vaultwarden (via sops template) | `/run/secrets/rendered/vaultwarden.env` |
| `wagou-password-hash` | User password | `/run/secrets/wagou-password-hash` |
| `root-password-hash` | Root password | `/run/secrets/root-password-hash` |
| `immich-api-key` | Homepage widget (via sops template) | `/run/secrets/rendered/homepage.env` |
| `adguard-password` | Homepage widget (via sops template) | `/run/secrets/rendered/homepage.env` |
| `cloudflare-api-token` | Homepage widget (via sops template) | `/run/secrets/rendered/homepage.env` |

### Editing secrets

```bash
sops hosts/nixos/homeserver/secrets.yaml
```

Or in Neovim (sops.nvim auto-decrypts):

```bash
nvim hosts/nixos/homeserver/secrets.yaml
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
| `*.wagou.fr` (local devices) | AdGuard Home rewrite -> `192.168.68.65` (direct, bypasses Cloudflare) |
| Ad/tracker domains | AdGuard Home -> blocked (`0.0.0.0`) |
| Everything else | AdGuard Home -> Cloudflare/Google DoH -> Internet |

### Domain

| Component | Provider |
|---|---|
| Registrar | OVH (`wagou.fr`) |
| DNS | Cloudflare (nameservers pointed from OVH) |
| TLS certificates | Cloudflare (auto-provisioned) |
| Email | OVH Zimbra (MX records in Cloudflare) |
| Tunnel | Cloudflare Zero Trust |

## Adding a new service

1. **Create** `services/<newservice>.nix` with the NixOS service config
2. **Import** it in `services/default.nix`
3. **Add Caddy virtual host** in `services/caddy.nix`:
   ```nix
   "http://newservice.wagou.fr".extraConfig = ''
     reverse_proxy 127.0.0.1:${toString config.services.newservice.port}
   '';
   ```
4. **Add DNS rewrite** in `services/adguardhome.nix` (for local LAN shortcut):
   ```nix
   { domain = "newservice.${domain}"; answer = serverIP; enabled = true; }
   ```
5. **Add secrets** if needed in `services/secrets.nix`
6. **Add Cloudflare Tunnel route** in dashboard: subdomain `newservice`, domain `wagou.fr`, type `HTTP`, URL `localhost:80`
7. **Push and rebuild**:
   ```bash
   git add -A && git commit -m "feat: add newservice" && git push
   sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#homeserver --refresh
   ```

## Quick reference

| Action | Command |
|---|---|
| SSH into server | `ssh homeserver` |
| Rebuild from GitHub | `sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#homeserver --refresh` |
| Check service status | `systemctl status <service>` |
| View service logs | `journalctl -u <service> --no-pager -f` |
| Stop/start a service | `sudo systemctl stop/start <service>` |
| Edit secrets | `sops hosts/nixos/homeserver/secrets.yaml` |
| Test build locally | `nix eval .#nixosConfigurations.homeserver.config.system.build.toplevel.drvPath` |
| AdGuard Home dashboard | `http://192.168.68.65:3000` |
| Homepage dashboard | `https://home.wagou.fr` |
| Vaultwarden | `https://vault.wagou.fr` |
| OpenCloud | `https://cloud.wagou.fr` |
| Immich | `https://pixel.wagou.fr` |

## Planned services

| Service | Purpose | Status |
|---|---|---|
| Home Assistant | Home automation (Docker via `oci-containers`) | Planned |
| Ollama | Local LLM inference | Planned |
| Backups | borgbackup/restic to external drive or cloud | Planned |
| Monitoring | Uptime Kuma or similar | Planned |
