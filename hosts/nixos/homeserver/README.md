# Homeserver

NixOS on a Beelink EQI13 (x86_64-linux, 32 GB RAM, 512 GB NVMe) running self-hosted services with network-wide ad blocking and secure remote access.

## Architecture

```
Remote (phone/laptop outside home)
  ── https://vault.wagou.fr ──▶ Cloudflare (valid TLS) ──▶ Tunnel (encrypted)
                                                                │
Local (home network)                                            │
  ── http://vault.wagou.fr ──▶ AdGuard Home (DNS) ─────────────┤
                                                                ▼
                                                          Caddy (HTTP :80)
                                                                │
                                                          Vaultwarden (:8222)
```

All devices on the network use the Beelink as their DNS server. AdGuard Home resolves service hostnames locally and blocks ads network-wide. Cloudflare Tunnel provides secure remote access without opening any ports on the router.

## Services

| Service | Purpose | Access | Port |
|---|---|---|---|
| **Vaultwarden** | Password manager (Bitwarden-compatible) | `https://vault.wagou.fr` (everywhere), `http://vault.home.lan` (local shortcut) | 8222 (localhost) |
| **Caddy** | Reverse proxy | Routes traffic to services | 80 |
| **AdGuard Home** | DNS server + ad blocker | `http://192.168.68.65:3000` (local only) | 53 (DNS), 3000 (web UI) |
| **Cloudflare Tunnel** | Secure remote access | Outbound connection to Cloudflare | None (outbound only) |
| **Docker** | Container runtime (for future services) | - | - |

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

## Network setup

The Beelink serves as the DNS server for the entire home network via AdGuard Home.

### Router configuration (TP-Link Deco)

- **DHCP DNS server**: `192.168.68.65` (the Beelink)
- **IPv6**: Disabled (forces all devices to use the Beelink for IPv4 DNS)
- **DHCP reservation**: Set for the Beelink to always get `192.168.68.65`

### DNS resolution flow

| Query | Resolution |
|---|---|
| `vault.wagou.fr` (local & remote) | Cloudflare DNS -> Cloudflare Tunnel -> Beelink |
| `vault.home.lan` (local shortcut) | AdGuard Home rewrite -> `192.168.68.65` (direct) |
| `ads.tracker.com` | AdGuard Home -> blocked (`0.0.0.0`) |
| `google.com` | AdGuard Home -> Cloudflare/Google DoH -> Internet |

### Domain

- **Registrar**: OVH (`wagou.fr`)
- **DNS**: Cloudflare (nameservers pointed from OVH to Cloudflare)
- **TLS**: Cloudflare manages public HTTPS certificates
- **Tunnel**: Cloudflare Zero Trust tunnel for remote access without open ports

## Files

```
hosts/nixos/homeserver/
├── default.nix      # Imports hardware.nix and services.nix
├── variables.nix    # Host variables (username, homeDir, hostname)
├── hardware.nix     # Auto-generated hardware config (boot, filesystems, kernel modules)
└── services.nix     # All services (Vaultwarden, Caddy, AdGuard Home, Cloudflare Tunnel)
```

## Secrets

The Cloudflare Tunnel token is stored on the server at `/var/lib/cloudflared/tunnel-token`. It is **not** in the Git repository.

### Placing the tunnel token (one-time setup)

```bash
ssh wagou@192.168.68.65
sudo mkdir -p /var/lib/cloudflared
echo -n 'YOUR_TUNNEL_TOKEN' | sudo tee /var/lib/cloudflared/tunnel-token > /dev/null
sudo chmod 600 /var/lib/cloudflared/tunnel-token
```

The token is obtained from the Cloudflare Zero Trust dashboard under Networks > Tunnels.

## Adding a new service

1. Add the NixOS service config to `services.nix` under the `services` block
2. Add a Caddy virtual host for the new service:
   ```nix
   caddy.virtualHosts."http://newservice.wagou.fr".extraConfig = ''
     reverse_proxy 127.0.0.1:<port> {
       header_up X-Real-IP {remote_host}
     }
   '';
   ```
3. Add a DNS rewrite in AdGuard Home settings:
   ```nix
   { domain = "newservice.wagou.fr"; answer = serverIP; enabled = true; }
   ```
4. Add a public hostname in the Cloudflare Tunnel dashboard (Zero Trust > Networks > Tunnels > Configure):
   - Subdomain: `newservice`
   - Domain: `wagou.fr`
   - Type: `HTTP`
   - URL: `localhost:80`
5. Open any additional firewall ports if needed
6. Push and rebuild:
   ```bash
   sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#homeserver --refresh
   ```

## Quick reference

| Action | Command |
|---|---|
| Rebuild from GitHub | `sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#homeserver --refresh` |
| Rebuild locally | `sudo nixos-rebuild switch --flake /path/to/wagounix#homeserver` |
| SSH into server | `ssh wagou@192.168.68.65` |
| Check service status | `systemctl status <service>` |
| Check tunnel status | `systemctl status cloudflared-tunnel` |
| View tunnel logs | `journalctl -u cloudflared-tunnel --no-pager -f` |
| View Caddy logs | `journalctl -u caddy --no-pager -f` |
| AdGuard Home dashboard | `http://192.168.68.65:3000` |
| Vaultwarden | `https://vault.wagou.fr` |

## Planned services

| Service | Purpose | Status |
|---|---|---|
| Nextcloud | Private cloud / file sync | Planned |
| Jellyfin | Media server | Planned |
| Home Assistant | Home automation (Docker) | Planned |
| Ollama | Local LLM inference | Planned |
