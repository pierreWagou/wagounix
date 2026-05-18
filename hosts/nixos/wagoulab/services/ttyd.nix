{ pkgs, host, ... }:

{
  environment.systemPackages = [ pkgs.ttyd ];

  # ttyd — web-based terminal for remote development access.
  # Exposes a tmux session via WebSocket, routed through Traefik at dev.wagou.fr.
  # Authentication is handled by Cloudflare Access (Zero Trust) — no basic auth here.
  # Binds only to the LAN IP (not exposed by the firewall, only reachable by Traefik).
  systemd.services.ttyd = {
    description = "ttyd - Web Terminal";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = host.username;
      Group = "users";
      WorkingDirectory = host.homeDir;
      ExecStart = "${pkgs.ttyd}/bin/ttyd --writable --port 7681 --interface ${host.serverIP} ${pkgs.tmux}/bin/tmux new-session -A -s main";
      Restart = "on-failure";
      RestartSec = 5;
    };
    # Ensure tools needed for the dev workflow (sesh, tv, nvim, etc.) are in PATH
    path = with pkgs; [
      zsh
      tmux
      tmuxinator
      neovim
      sesh
      television
      git
      fzf
      zoxide
      eza
      ripgrep
      fd
      bat
    ];
  };
}
