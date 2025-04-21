{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      theme = "catppuccin-mocha";
      font-family = "JetBrainsMono Nerd Font Mono";
      title = "";
      link-url = true;
      copy-on-select = "clipboard";
      shell-integration-features = "title, sudo, no-cursor";
      window-title-font-family = "JetBrainsMono Nerd Font Mono";
      window-padding-x = 10;
      window-save-state = "always";
      window-padding-balance = true;
      cursor-style = "block";
      cursor-invert-fg-bg = true;
      macos-titlebar-style = "tabs";
      macos-titlebar-proxy-icon = "hidden";
      macos-auto-secure-input = true;
      macos-secure-input-indication = true;
      auto-update = "download";
      auto-update-channel = "stable";
    };
  };
}