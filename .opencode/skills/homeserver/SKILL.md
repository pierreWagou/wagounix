---
name: homeserver
description: Manage the NixOS homeserver — add services, configure DNS rewrites, Cloudflare Tunnel routes, Caddy reverse proxy, and troubleshoot the Beelink EQI13.
---

## Overview

The homeserver is a Beelink EQI13 running NixOS (x86_64-linux, 32 GB RAM, 512 GB NVMe) at IP `192.168.68.65`. It serves as a self-hosted service platform with network-wide ad blocking and secure remote access via Cloudflare Tunnel.

Domain: `wagou.fr` (registered at OVH, DNS managed by Cloudflare)

## Architecture

```
Remote access:  Browser -> Cloudflare (HTTPS) -> Tunnel (encrypted) -> Caddy (HTTP :80) -> Service
Local access:   Browser -> AdGuard Home (DNS rewrite to 192.168.68.65) -> Caddy (HTTP :80) -> Service
```

Caddy serves HTTP only. Cloudflare handles public-facing HTTPS with valid certificates. Internal traffic between the tunnel and Caddy is plain HTTP on localhost — no TLS needed.

## Current services

| Service | NixOS module | Port | Local URL | Remote URL |
|---|---|---|---|---|
| Vaultwarden | `services.vaultwarden` | 8222 (localhost) | `http://vault.wagou.fr` | `https://vault.wagou.fr` |
| Caddy | `services.caddy` | 80 | - | - |
| AdGuard Home | `services.adguardhome` | 53 (DNS), 3000 (web UI) | `http://192.168.68.65:3000` | Not exposed |
| Cloudflare Tunnel | `systemd.services.cloudflared-tunnel` | Outbound only | - | - |
| Docker | `virtualisation.docker` | - | - | - |

## Files

All homeserver config is in `hosts/nixos/homeserver/`:

| File | Purpose |
|---|---|
| `default.nix` | Imports hardware.nix and services.nix |
| `variables.nix` | Host variables: `username = "wagou"`, `hostname = "homeserver"` |
| `hardware.nix` | Auto-generated hardware config from `nixos-generate-config` (boot, filesystems, kernel modules, Intel microcode) |
| `services.nix` | All services, firewall rules, and the cloudflared systemd unit |

Platform-level NixOS config is in `hosts/nixos/`:

| File | Purpose |
|---|---|
| `default.nix` | Imports configuration.nix |
| `configuration.nix` | System config: SSH, Docker, user account, timezone, locale, firewall base |

## Adding a new service

### Step 1 — Add the NixOS service to `services.nix`

Add the service under the `services` block:

```nix
services = {
  # ... existing services ...

  newservice = {
    enable = true;
    # service-specific options
  };
};
```

### Step 2 — Add a Caddy reverse proxy entry

```nix
caddy.virtualHosts."http://newservice.wagou.fr".extraConfig = ''
  reverse_proxy 127.0.0.1:<SERVICE_PORT> {
    header_up X-Real-IP {remote_host}
  }
'';
```

### Step 3 — Add a DNS rewrite in AdGuard Home

Add to the `filtering.rewrites` list:

```nix
{
  domain = "newservice.wagou.fr";
  answer = serverIP;
  enabled = true;
}
```

IMPORTANT: The `enabled = true` field is required — AdGuard Home defaults to `false` if omitted.

### Step 4 — Open firewall ports (if needed)

If the service needs additional ports beyond 80 (HTTP) and 53 (DNS), add them:

```nix
networking.firewall = {
  allowedTCPPorts = [ 80 53 <new-port> ];
  allowedUDPPorts = [ 53 ];
};
```

### Step 5 — Add a Cloudflare Tunnel route (for remote access)

In the Cloudflare Zero Trust dashboard:
1. Go to **Networks > Tunnels** > click your tunnel
2. Under the **Route** tab, add a **Published Application**:
   - Subdomain: `newservice`
   - Domain: `wagou.fr`
   - Type: `HTTP`
   - URL: `localhost:80`

### Step 6 — Deploy

```bash
# Push changes
git add -A && git commit -m "feat: add newservice" && git push

# Rebuild on the Beelink
sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#homeserver --refresh
```

## Secrets management

The Cloudflare Tunnel token is stored at `/var/lib/cloudflared/tunnel-token` on the server. It is NOT in the Git repository.

### Placing the tunnel token (one-time)

```bash
ssh wagou@192.168.68.65
sudo mkdir -p /var/lib/cloudflared
echo -n 'TOKEN' | sudo tee /var/lib/cloudflared/tunnel-token > /dev/null
sudo chmod 600 /var/lib/cloudflared/tunnel-token
```

The token is obtained from Cloudflare Zero Trust > Networks > Tunnels > your tunnel.

## Network configuration

### Router (TP-Link Deco)

| Setting | Value | Notes |
|---|---|---|
| DHCP DNS server | `192.168.68.65` | All devices use the Beelink for DNS |
| IPv6 | Disabled | Forces IPv4 DNS through the Beelink |
| DHCP reservation | `192.168.68.65` for Beelink MAC | Ensures stable IP |

### Why IPv6 is disabled

macOS and iOS prefer IPv6 DNS servers. The Deco advertises itself as the IPv6 DNS server via Router Advertisement, and there's no way to change this on the Deco. Disabling IPv6 forces all devices to use the Beelink's IPv4 DNS.

### Domain setup

| Component | Provider | Notes |
|---|---|---|
| Domain registrar | OVH | `wagou.fr` |
| DNS | Cloudflare | OVH nameservers changed to Cloudflare's |
| TLS certificates | Cloudflare | Auto-provisioned for public access |
| Email | OVH Zimbra | MX records in Cloudflare point to OVH mail servers |

### DNS behavior

| Scenario | Resolution path |
|---|---|
| Any device queries `vault.wagou.fr` | Cloudflare DNS -> Cloudflare Tunnel -> Beelink (HTTPS everywhere, consistent) |
| Local device queries `vault.home.lan` | AdGuard Home rewrite -> `192.168.68.65` (direct HTTP shortcut) |
| Any device queries `ads.tracker.com` | AdGuard Home -> blocked (`0.0.0.0`) |
| Any device queries `google.com` | AdGuard Home -> upstream DoH (Cloudflare/Google) -> Internet |

## AdGuard Home configuration

AdGuard Home runs with `mutableSettings = false` — the config is fully declarative and reset on every rebuild. Web UI changes are lost on restart.

### Upstream DNS

Uses DNS-over-HTTPS for encrypted upstream queries:
- `https://dns.cloudflare.com/dns-query`
- `https://dns.google/dns-query`

### Blocklists

| ID | Name | URL |
|---|---|---|
| 1 | AdGuard DNS filter | `https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt` |
| 2 | Steven Black's Unified Hosts | `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` |
| 3 | Malicious URL Blocklist | `https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt` |

## Troubleshooting

### "Internet not available" notification on macOS

This is a false alarm caused by disabling IPv6 on the Deco. macOS's connectivity check may partially fail without IPv6. Internet works fine over IPv4. If AdGuard Home is blocking `captive.apple.com`, add it to the allowlist.

### Ghostty terminal error when SSHing

If you see `'xterm-ghostty': unknown terminal type`, the `ghostty.terminfo` package is already installed on the server. If it happens again, run `export TERM=xterm-256color` as a workaround.

### Cloudflare Tunnel not connecting

1. Check the service: `systemctl status cloudflared-tunnel`
2. Check logs: `journalctl -u cloudflared-tunnel --no-pager -f`
3. Verify the token file exists: `ls -la /var/lib/cloudflared/tunnel-token`
4. Common errors:
   - "Provided Tunnel token is not valid" — token file has extra whitespace or newline. Recreate with `echo -n`
   - Service crash-looping — check logs for the specific error

### 502 Bad Gateway from Cloudflare

The tunnel is connected but the local service isn't responding correctly. Check:
1. Is Caddy running? `systemctl status caddy`
2. Is the target service running? `systemctl status vaultwarden`
3. Test locally: `curl -H "Host: vault.wagou.fr" http://localhost:80`
4. Ensure the Cloudflare Tunnel route uses `HTTP` (not `HTTPS`) with URL `localhost:80`

### DNS not resolving locally

1. Check your Mac's DNS: `scutil --dns | grep nameserver`
2. Should show `192.168.68.65`
3. If not, force DHCP renewal: `sudo ipconfig set en0 DHCP`
4. Test DNS directly: `nslookup vault.wagou.fr 192.168.68.65`
5. Do NOT use `.local` domains — macOS intercepts them for mDNS (Bonjour). Use `.lan`, `.home.arpa`, or a real domain.

## Key commands

| Action | Command |
|---|---|
| Rebuild from GitHub | `sudo nixos-rebuild switch --flake github:pierreWagou/wagounix#homeserver --refresh` |
| SSH into server | `ssh wagou@192.168.68.65` |
| Check service status | `systemctl status <service>` |
| View service logs | `journalctl -u <service> --no-pager -f` |
| AdGuard Home dashboard | `http://192.168.68.65:3000` |

## Important rules

- All service config goes in `hosts/nixos/homeserver/services.nix` — keep everything in one file
- Secrets (tokens, API keys) go in files on the server, NOT in the Git repo
- AdGuard Home DNS rewrites need `enabled = true` — it defaults to `false`
- Caddy serves HTTP only — Cloudflare handles public HTTPS
- Cloudflare Tunnel routes must use `HTTP` type with `localhost:80` — not HTTPS
- `system.stateVersion = "25.05"` — never change this
- `hardware.nix` was generated by `nixos-generate-config` — only regenerate if hardware changes
- Do NOT add AdGuard Home DNS rewrites for `*.wagou.fr` domains — let them resolve via Cloudflare so HTTPS works consistently everywhere. Only use `.home.lan` rewrites for direct local HTTP shortcuts.
- Always test builds before pushing: `nix eval .#nixosConfigurations.homeserver.config.system.build.toplevel.drvPath`
