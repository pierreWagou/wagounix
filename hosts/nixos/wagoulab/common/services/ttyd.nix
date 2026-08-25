{ pkgs, host, ... }:

let
  # Catppuccin Mocha theme for xterm.js (ttyd's terminal renderer)
  catppuccinMocha = builtins.toJSON {
    background = "#1e1e2e";
    foreground = "#cdd6f4";
    cursor = "#f5e0dc";
    cursorAccent = "#1e1e2e";
    selectionBackground = "#45475a";
    selectionForeground = "#cdd6f4";
    black = "#45475a";
    red = "#f38ba8";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    blue = "#89b4fa";
    magenta = "#f5c2e7";
    cyan = "#94e2d5";
    white = "#bac2de";
    brightBlack = "#585b70";
    brightRed = "#f38ba8";
    brightGreen = "#a6e3a1";
    brightYellow = "#f9e2af";
    brightBlue = "#89b4fa";
    brightMagenta = "#f5c2e7";
    brightCyan = "#94e2d5";
    brightWhite = "#a6adc8";
  };
in
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
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.ttyd}/bin/ttyd"
        "--writable"
        "--port ${toString host.ports.ttyd}"
        "--interface ${host.serverIP}"
        "--client-option fontFamily='JetBrainsMono Nerd Font Mono,monospace'"
        "--client-option fontSize=14"
        "--client-option theme='${catppuccinMocha}'"
        "${pkgs.tmux}/bin/tmux new-session -A -s main"
      ];
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
