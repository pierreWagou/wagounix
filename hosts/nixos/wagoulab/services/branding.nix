{
  config,
  lib,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks;

  # === Catppuccin Palettes ===
  mocha = {
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
    surface0 = "#313244";
    surface1 = "#45475a";
    surface2 = "#585b70";
    overlay0 = "#6c7086";
    overlay1 = "#7f849c";
    text = "#cdd6f4";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";
    mauve = "#cba6f7";
    lavender = "#b4befe";
    red = "#f38ba8";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    peach = "#fab387";
    blue = "#89b4fa";
  };

  latte = {
    base = "#eff1f5";
    mantle = "#e6e9ef";
    crust = "#dce0e8";
    surface0 = "#ccd0da";
    surface1 = "#bcc0cc";
    surface2 = "#acb0be";
    overlay0 = "#9ca0b0";
    overlay1 = "#8c8fa1";
    text = "#4c4f69";
    subtext0 = "#6c6f85";
    subtext1 = "#5c5f77";
    mauve = "#8839ef";
    lavender = "#7287fd";
    red = "#d20f39";
    green = "#40a02b";
    yellow = "#df8e1d";
    peach = "#fe640b";
    blue = "#1e66f5";
  };

  gradient = {
    start = "#ff6b6b";
    mid = "#ff2ecc";
    end = "#7b2eff";
  };

  # === Logo Generator ===
  mkLogo =
    name:
    let
      textContent = "WAGOU ${name}";
      textLen = builtins.stringLength textContent;
      textWidth = textLen * 12 + 16;
      totalWidth = 38 + textWidth;
    in
    pkgs.writeText "logo-${lib.toLower name}.svg" ''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${toString totalWidth} 40" preserveAspectRatio="xMinYMid meet">
        <defs>
          <linearGradient id="sun" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="${gradient.start}"/>
            <stop offset="50%" stop-color="${gradient.mid}"/>
            <stop offset="100%" stop-color="${gradient.end}"/>
          </linearGradient>
          <clipPath id="stripes">
            <rect x="0" y="0" width="32" height="17"/>
            <rect x="0" y="19" width="32" height="2"/>
            <rect x="0" y="23" width="32" height="2"/>
            <rect x="0" y="27" width="32" height="2"/>
          </clipPath>
        </defs>
        <circle cx="16" cy="20" r="12" fill="url(#sun)" clip-path="url(#stripes)"/>
        <text x="38" y="27"
              font-family="'JetBrains Mono', 'Fira Code', monospace"
              font-size="16"
              font-weight="700"
              letter-spacing="2"
              fill="url(#sun)">WAGOU ${name}</text>
      </svg>
    '';

  # === Combined branding directory (real file copies for imgproxy) ===
  brandingDir = pkgs.runCommand "branding-dir" { } ''
    mkdir -p $out
    cp ${./branding-assets}/* $out/
    cp ${mkLogo "AUTH"} $out/logo-auth.svg
    cp ${mkLogo "DISK"} $out/logo-disk.svg
  '';

  # === imgproxy URL base ===
  assetsBaseUrl = "https://assets.${host.domain}/insecure";

  # === Pre-built URLs for common assets ===
  urls = {
    favicon = "${assetsBaseUrl}/plain/local:///favicon.svg";
    logoAuth = "${assetsBaseUrl}/plain/local:///logo-auth.svg";
    logoDisk = "${assetsBaseUrl}/plain/local:///logo-disk.svg";
    bgCity = "${assetsBaseUrl}/plain/local:///city.jpg";
  };

in
{
  options.wagou.branding = {
    palette.mocha = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = mocha;
      readOnly = true;
      description = "Catppuccin Mocha palette (dark mode)";
    };
    palette.latte = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = latte;
      readOnly = true;
      description = "Catppuccin Latte palette (light mode)";
    };
    css.ctpVars = lib.mkOption {
      type = lib.types.str;
      default = ''
        :root {
          --ctp-base:     ${mocha.base};
          --ctp-mantle:   ${mocha.mantle};
          --ctp-crust:    ${mocha.crust};
          --ctp-surface0: ${mocha.surface0};
          --ctp-surface1: ${mocha.surface1};
          --ctp-surface2: ${mocha.surface2};
          --ctp-overlay0: ${mocha.overlay0};
          --ctp-text:     ${mocha.text};
          --ctp-subtext0: ${mocha.subtext0};
          --ctp-subtext1: ${mocha.subtext1};
          --ctp-lavender: ${mocha.lavender};
          --ctp-mauve:    ${mocha.mauve};
          --ctp-green:    ${mocha.green};
          --ctp-red:      ${mocha.red};
          --ctp-peach:    ${mocha.peach};
          --ctp-blue:     ${mocha.blue};
        }
      '';
      readOnly = true;
      description = "CSS :root block defining Catppuccin Mocha --ctp-* custom properties";
    };
    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = assetsBaseUrl;
      readOnly = true;
      description = "Base URL for imgproxy branding assets";
    };
    urls = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = urls;
      readOnly = true;
      description = "Pre-built URLs for common branding assets";
    };
  };

  config = {
    # === imgproxy container for serving branding assets ===
    virtualisation.quadlet.containers.imgproxy = {
      containerConfig = {
        image = "docker.io/darthsim/imgproxy:v4.0.3";
        noNewPrivileges = true;
        networks = [ networks.proxy.ref ];
        volumes = [ "${brandingDir}:/images:ro" ];
        environments = {
          IMGPROXY_LOCAL_FILESYSTEM_ROOT = "/images";
          IMGPROXY_ALLOWED_SOURCES = "local://";
          IMGPROXY_WORKERS = "2";
          IMGPROXY_MALLOC = "jemalloc";
          IMGPROXY_TTL = "86400";
          IMGPROXY_USE_ETAG = "true";
          IMGPROXY_SKIP_PROCESSING_FORMATS = "svg";
          IMGPROXY_SANITIZE_SVG = "true";
          IMGPROXY_MAX_SRC_RESOLUTION = "50";
          IMGPROXY_QUALITY = "80";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.imgproxy.rule" = "Host(`assets.${host.domain}`)";
          "traefik.http.routers.imgproxy.entrypoints" = "websecure";
          "traefik.http.routers.imgproxy.tls" = "true";
          "traefik.http.routers.imgproxy.middlewares" = "secure-headers@file";
          "traefik.http.services.imgproxy.loadbalancer.server.port" = "8080";
        };
      };
    };
  };
}
