{
  lib,
  pkgs,
  ...
}:

with lib;

let
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

  # === Backgrounds ===
  backgrounds = {
    ocean = ./branding-assets/ocean.jpg;
    city = ./branding-assets/city.jpg;
    bridge = ./branding-assets/bridge.jpg;
    dock = ./branding-assets/dock.jpg;
    hood = ./branding-assets/hood.jpg;
    river = ./branding-assets/river.jpg;
    street = ./branding-assets/street.jpg;
  };

  # === Favicon (synthwave sunset) ===
  favicon = ./branding-assets/favicon.svg;

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

  # === Authentik CSS ===
  authentikCss = ''
    /* Catppuccin for Authentik — Light: Latte, Dark: Mocha */

    /* === Light mode === */
    :root {
      --ak-accent: ${latte.mauve};
      --pf-global--primary-color--100: ${latte.mauve};
      --pf-global--primary-color--dark-100: ${latte.mauve};
      --pf-global--link--Color: ${latte.mauve};
      --pf-global--link--Color--hover: ${latte.lavender};
      --pf-global--link--Color--dark: ${latte.mauve};
      --pf-global--link--Color--dark--hover: ${latte.lavender};
      --pf-global--BackgroundColor--100: ${latte.base};
      --pf-global--BackgroundColor--200: ${latte.mantle};
      --pf-global--Color--100: ${latte.text};
      --pf-global--Color--200: ${latte.subtext0};
      --pf-global--BorderColor--100: ${latte.surface0};
      --pf-global--active-color--100: ${latte.mauve};
    }

    /* === Dark mode === */
    html[data-theme=dark] {
      --ak-accent: ${mocha.mauve};
      --ak-dark-background: ${mocha.base};
      --ak-dark-background-light: ${mocha.mantle};
      --ak-dark-background-lighter: ${mocha.surface0};
      --ak-dark-foreground: ${mocha.text};
      --pf-global--primary-color--100: ${mocha.mauve};
      --pf-global--primary-color--light-100: ${mocha.mauve};
      --pf-global--link--Color: ${mocha.mauve};
      --pf-global--link--Color--hover: ${mocha.lavender};
      --pf-global--link--Color--light: ${mocha.mauve};
      --pf-global--BackgroundColor--100: ${mocha.base};
      --pf-global--BackgroundColor--200: ${mocha.mantle};
      --pf-global--BackgroundColor--dark-100: ${mocha.base};
      --pf-global--BackgroundColor--dark-200: ${mocha.mantle};
      --pf-global--BackgroundColor--dark-300: ${mocha.surface0};
      --pf-global--BackgroundColor--light-100: ${mocha.surface0};
      --pf-global--BackgroundColor--light-300: ${mocha.surface1};
      --pf-global--Color--100: ${mocha.text};
      --pf-global--Color--200: ${mocha.subtext0};
      --pf-global--Color--light-100: ${mocha.crust};
      --pf-global--BorderColor--100: ${mocha.surface1};
      --pf-global--active-color--100: ${mocha.mauve};
    }

    /* === Buttons (direct overrides for Shadow DOM penetration) === */
    .pf-c-button.pf-m-primary {
      background-color: var(--ak-accent) !important;
      border-color: var(--ak-accent) !important;
      color: ${mocha.crust} !important;
    }
    .pf-c-button.pf-m-primary:hover,
    .pf-c-button.pf-m-primary:focus {
      background-color: ${mocha.lavender} !important;
      border-color: ${mocha.lavender} !important;
    }
    .pf-c-button.pf-m-secondary {
      border-color: var(--ak-accent) !important;
      color: var(--ak-accent) !important;
    }
    .pf-c-button.pf-m-secondary:hover {
      background-color: var(--ak-accent) !important;
      color: ${mocha.crust} !important;
    }
    .pf-c-button.pf-m-link {
      color: var(--ak-accent) !important;
    }
    .pf-c-button.pf-m-link:hover {
      color: ${mocha.lavender} !important;
    }

    /* === Links & clickable text === */
    a, a:visited {
      color: var(--pf-global--link--Color) !important;
    }
    a:hover {
      color: var(--pf-global--link--Color--hover) !important;
    }

    /* === Switches / toggles === */
    .pf-c-switch__input:checked ~ .pf-c-switch__toggle {
      background-color: ${mocha.green} !important;
    }
    .pf-c-switch__input:checked ~ .pf-c-switch__toggle::before {
      border-color: ${mocha.green} !important;
    }

    /* === Tabs (admin navigation) === */
    .pf-c-tabs__link::after {
      border-bottom-color: transparent !important;
    }
    .pf-c-tabs__item.pf-m-current .pf-c-tabs__link::after {
      border-bottom-color: var(--ak-accent) !important;
    }
    .pf-c-tabs__item.pf-m-current .pf-c-tabs__link {
      color: var(--ak-accent) !important;
    }

    /* === Badges / labels === */
    .pf-c-badge.pf-m-read {
      background-color: ${mocha.surface1} !important;
      color: ${mocha.text} !important;
    }
    .pf-c-badge.pf-m-unread {
      background-color: var(--ak-accent) !important;
      color: ${mocha.crust} !important;
    }

    /* === Charts / diagrams — use Catppuccin palette === */
    .ct-series-a .ct-bar,
    .ct-series-a .ct-line,
    .ct-series-a .ct-point,
    .ct-series-a .ct-slice-donut,
    .ct-series-a .ct-area {
      stroke: ${mocha.mauve} !important;
      fill: ${mocha.mauve} !important;
    }
    .ct-series-b .ct-bar,
    .ct-series-b .ct-line,
    .ct-series-b .ct-point,
    .ct-series-b .ct-slice-donut,
    .ct-series-b .ct-area {
      stroke: ${mocha.blue} !important;
      fill: ${mocha.blue} !important;
    }
    .ct-series-c .ct-bar,
    .ct-series-c .ct-line,
    .ct-series-c .ct-point,
    .ct-series-c .ct-slice-donut,
    .ct-series-c .ct-area {
      stroke: ${mocha.green} !important;
      fill: ${mocha.green} !important;
    }
    .ct-series-d .ct-bar,
    .ct-series-d .ct-line,
    .ct-series-d .ct-point,
    .ct-series-d .ct-slice-donut,
    .ct-series-d .ct-area {
      stroke: ${mocha.peach} !important;
      fill: ${mocha.peach} !important;
    }
    .ct-series-e .ct-bar,
    .ct-series-e .ct-line,
    .ct-series-e .ct-point,
    .ct-series-e .ct-slice-donut,
    .ct-series-e .ct-area {
      stroke: ${mocha.lavender} !important;
      fill: ${mocha.lavender} !important;
    }
    /* Chart.js canvas fallback */
    canvas {
      filter: hue-rotate(0deg) !important;
    }
    /* Chart grid lines */
    .ct-grid {
      stroke: ${mocha.surface1} !important;
    }
    .ct-label {
      color: ${mocha.subtext0} !important;
      fill: ${mocha.subtext0} !important;
    }

    /* === Cards (admin panels) === */
    .pf-c-card {
      --pf-c-card--BackgroundColor: ${mocha.surface0} !important;
      background-color: ${mocha.surface0} !important;
      border-color: ${mocha.surface1} !important;
    }

    /* === Navigation active indicator === */
    .pf-c-nav__link.pf-m-current,
    .pf-c-nav__link.pf-m-current::after {
      color: var(--ak-accent) !important;
      border-left-color: var(--ak-accent) !important;
    }

    /* === Form inputs === */
    .pf-c-form-control:focus {
      border-color: var(--ak-accent) !important;
      box-shadow: 0 0 0 1px var(--ak-accent) !important;
    }

    /* === Progress / loading === */
    .pf-c-spinner__path {
      stroke: var(--ak-accent) !important;
    }

    /* === Chips / tags === */
    .pf-c-chip {
      background-color: ${mocha.surface0} !important;
      border-color: ${mocha.surface1} !important;
    }

    /* === Login page === */
    .pf-c-login__main {
      background-color: rgba(49, 50, 68, 0.85) !important;
      border: 1px solid ${mocha.surface1} !important;
      border-radius: 8px !important;
      backdrop-filter: blur(10px) !important;
    }
    @media (prefers-color-scheme: light) {
      .pf-c-login__main {
        background-color: rgba(239, 241, 245, 0.85) !important;
        border: 1px solid ${latte.surface0} !important;
      }
    }

    /* === Scrollbar === */
    ::-webkit-scrollbar { width: 8px; }
    ::-webkit-scrollbar-track { background: ${mocha.mantle}; }
    ::-webkit-scrollbar-thumb { background: ${mocha.surface1}; border-radius: 4px; }
    ::-webkit-scrollbar-thumb:hover { background: ${mocha.surface2}; }

    /* === Selection === */
    ::selection {
      background-color: rgba(203, 166, 247, 0.3);
      color: ${mocha.text};
    }
  '';

  # === Seafile CSS (full theme) ===
  # Uses palette variables for generation, outputs CSS custom properties for runtime
  l = latte;
  m = mocha;

  seafileCss = pkgs.writeText "seafile-custom.css" ''
    /* Catppuccin Theme for Seafile v13 — Generated by wagou.branding
       Light: Latte | Dark: Mocha | Accent: Mauve */

    /* === LIGHT MODE: Catppuccin Latte === */
    :root,
    [data-bs-theme=light] {
      --ctp-base: ${l.base}; --ctp-mantle: ${l.mantle}; --ctp-crust: ${l.crust};
      --ctp-surface0: ${l.surface0}; --ctp-surface1: ${l.surface1}; --ctp-surface2: ${l.surface2};
      --ctp-overlay0: ${l.overlay0}; --ctp-overlay1: ${l.overlay1};
      --ctp-text: ${l.text}; --ctp-subtext0: ${l.subtext0}; --ctp-subtext1: ${l.subtext1};
      --ctp-mauve: ${l.mauve}; --ctp-lavender: ${l.lavender};
      --ctp-red: ${l.red}; --ctp-green: ${l.green}; --ctp-yellow: ${l.yellow};
      --ctp-peach: ${l.peach}; --ctp-blue: ${l.blue};
      --bs-body-color: ${l.text}; --bs-body-secondary-color: ${l.subtext0};
      --bs-body-bg: ${l.base}; --bs-body-secondary-bg: ${l.mantle};
      --bs-emphasis-color: ${l.text};
      --bs-border-color: ${l.surface0}; --bs-border-secondary-color: ${l.surface0}; --bs-border-tertiary-color: ${l.crust};
      --bs-secondary-color: ${l.subtext1}; --bs-tertiary-color: ${l.subtext0};
      --bs-header-bg: ${l.mantle}; --bs-header-secondary-bg: ${l.mantle}; --bs-header-tertiary-bg: ${l.crust};
      --bs-toolbar-bg: ${l.base}; --bs-toolbar-secondary-bg: ${l.mantle};
      --bs-nav-hover-bg: ${l.crust}; --bs-nav-active-bg: ${l.surface0};
      --bs-wiki-nav-hover-bg: ${l.crust}; --bs-wiki-nav-active-bg: ${l.surface0};
      --bs-th-bg: ${l.mantle}; --bs-th-secondary-bg: ${l.mantle}; --bs-th-tertiary-bg: ${l.base};
      --bs-th-quartus-bg: ${l.surface0}; --bs-th-fifth-bg: ${l.surface1};
      --bs-tr-active-bg: ${l.crust}; --bs-tr-active-secondary-bg: rgba(136, 57, 239, 0.1); --bs-tr-hover-bg: ${l.mantle};
      --bs-icon-color: ${l.subtext0}; --bs-icon-secondary-color: ${l.subtext0};
      --bs-icon-tertiary-color: ${l.overlay0}; --bs-icon-hover-color: ${l.mauve};
      --bs-hover-bg: ${l.mantle}; --bs-hover-secondary-bg: ${l.crust}; --bs-hover-tertiary-bg: ${l.surface0};
      --bs-bg-color: ${l.mantle}; --bs-bg-secondary-color: ${l.crust};
      --bs-dropdown-link-bg: ${l.mauve}; --bs-dropdown-secondary-bg: ${l.mantle}; --bs-dropdown-tertiary-bg: ${l.mantle};
      --bs-popover-bg: ${l.base}; --bs-placeholder-color: ${l.overlay0};
      --bs-primary: ${l.mauve}; --bs-primary-rgb: 136, 57, 239;
      --bs-link-color: ${l.mauve}; --bs-link-hover-color: ${l.lavender};
    }

    /* === DARK MODE: Catppuccin Mocha === */
    [data-bs-theme=dark] {
      --ctp-base: ${m.base}; --ctp-mantle: ${m.mantle}; --ctp-crust: ${m.crust};
      --ctp-surface0: ${m.surface0}; --ctp-surface1: ${m.surface1}; --ctp-surface2: ${m.surface2};
      --ctp-overlay0: ${m.overlay0}; --ctp-overlay1: ${m.overlay1};
      --ctp-text: ${m.text}; --ctp-subtext0: ${m.subtext0}; --ctp-subtext1: ${m.subtext1};
      --ctp-mauve: ${m.mauve}; --ctp-lavender: ${m.lavender};
      --ctp-red: ${m.red}; --ctp-green: ${m.green}; --ctp-yellow: ${m.yellow};
      --ctp-peach: ${m.peach}; --ctp-blue: ${m.blue};
      --bs-body-color: ${m.text}; --bs-body-secondary-color: ${m.subtext0};
      --bs-body-bg: ${m.base}; --bs-body-secondary-bg: ${m.surface0};
      --bs-emphasis-color: ${m.text};
      --bs-border-color: ${m.surface1}; --bs-border-secondary-color: ${m.surface1}; --bs-border-tertiary-color: ${m.surface0};
      --bs-secondary-color: ${m.subtext1}; --bs-tertiary-color: ${m.subtext0};
      --bs-header-bg: ${m.mantle}; --bs-header-secondary-bg: ${m.mantle}; --bs-header-tertiary-bg: ${m.crust};
      --bs-toolbar-bg: ${m.base}; --bs-toolbar-secondary-bg: ${m.mantle};
      --bs-nav-hover-bg: ${m.surface0}; --bs-nav-active-bg: ${m.surface0};
      --bs-wiki-nav-hover-bg: ${m.surface0}; --bs-wiki-nav-active-bg: ${m.surface1};
      --bs-th-bg: ${m.mantle}; --bs-th-secondary-bg: ${m.mantle}; --bs-th-tertiary-bg: ${m.base};
      --bs-th-quartus-bg: ${m.surface0}; --bs-th-fifth-bg: ${m.surface1};
      --bs-tr-active-bg: ${m.surface0}; --bs-tr-active-secondary-bg: rgba(203, 166, 247, 0.15); --bs-tr-hover-bg: ${m.surface0};
      --bs-icon-color: ${m.subtext0}; --bs-icon-secondary-color: ${m.subtext0};
      --bs-icon-tertiary-color: ${m.overlay0}; --bs-icon-hover-color: ${m.mauve};
      --bs-hover-bg: ${m.surface0}; --bs-hover-secondary-bg: ${m.surface1}; --bs-hover-tertiary-bg: ${m.surface2};
      --bs-bg-color: ${m.surface0}; --bs-bg-secondary-color: ${m.mantle};
      --bs-dropdown-link-bg: ${m.mauve}; --bs-dropdown-secondary-bg: ${m.surface0}; --bs-dropdown-tertiary-bg: ${m.surface0};
      --bs-popover-bg: ${m.surface0}; --bs-placeholder-color: ${m.overlay0};
      --bs-primary: ${m.mauve}; --bs-primary-rgb: 203, 166, 247;
      --bs-link-color: ${m.mauve}; --bs-link-hover-color: ${m.lavender};
      color-scheme: dark;
    }

    /* === STRUCTURAL OVERRIDES === */
    body, .page, .page-main, .page-content, .bg-white,
    #wrapper, .main-panel, .main-panel-center, .main-con,
    .page-single, .container, .container-fluid {
      background-color: var(--ctp-base) !important; color: var(--ctp-text) !important;
    }
    .aside { background-color: var(--ctp-mantle) !important; border-color: var(--ctp-surface1) !important; }
    .header, .top-header, .main-panel-north, #header { background-color: var(--ctp-mantle) !important; border-bottom: 1px solid var(--ctp-surface0) !important; }
    .side-panel, .side-nav, .side-nav-con, .left-panel { background-color: var(--ctp-mantle) !important; border-right: 1px solid var(--ctp-surface0) !important; }
    .side-nav .nav-item, .side-nav a, .side-panel a { color: var(--ctp-subtext0) !important; }
    .side-nav .nav-item:hover, .side-nav a:hover, .side-panel a:hover { color: var(--ctp-text) !important; background-color: var(--ctp-surface0) !important; }
    .side-nav .nav-item.active, .side-nav .nav-item.active a { color: var(--ctp-lavender) !important; background-color: var(--ctp-surface0) !important; }
    a { color: var(--ctp-mauve) !important; }
    a:hover { color: var(--ctp-lavender) !important; }

    /* Buttons */
    .btn-primary, .btn-primary:focus { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }
    .btn-primary:hover, .btn-primary:active, .btn-primary.active { background-color: var(--ctp-lavender) !important; border-color: var(--ctp-lavender) !important; color: var(--ctp-crust) !important; }
    .btn-primary:disabled, .btn-primary.disabled { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; opacity: 0.5 !important; }
    .btn-secondary, .btn-outline-primary { background-color: var(--ctp-surface0) !important; border-color: var(--ctp-surface1) !important; color: var(--ctp-text) !important; }
    .btn-secondary:hover, .btn-outline-primary:hover, .btn-outline-primary:active { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }

    /* Cards, modals, dropdowns */
    .card, .panel, .modal-content, .popover { background-color: var(--ctp-surface0) !important; border-color: var(--ctp-surface1) !important; color: var(--ctp-text) !important; }
    .modal-header, .modal-footer { border-color: var(--ctp-surface1) !important; }
    .dropdown-menu { background-color: var(--ctp-surface0) !important; border-color: var(--ctp-surface1) !important; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2) !important; }
    .dropdown-item { color: var(--ctp-text) !important; }
    .dropdown-item:hover, .dropdown-item:focus { background-color: var(--ctp-lavender) !important; color: var(--ctp-crust) !important; }
    .dropdown-item:active, .dropdown-item.active { background-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }

    /* Seafile popover */
    .sf-popover { background-color: var(--ctp-surface0) !important; border: 1px solid var(--ctp-surface1) !important; }
    .sf-popover-hd, .sf-popover-title { color: var(--ctp-text) !important; border-bottom: 1px solid var(--ctp-surface1) !important; }
    a.sf-popover-item { color: var(--ctp-text) !important; }
    a.sf-popover-item:hover { background-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }
    .sf-popover-con { background-color: var(--ctp-surface0) !important; }

    /* Forms & inputs */
    input, textarea, select, .form-control, .form-select { background-color: var(--ctp-surface0) !important; border-color: var(--ctp-surface1) !important; color: var(--ctp-text) !important; }
    input:focus, textarea:focus, select:focus, .form-control:focus, .form-select:focus { border-color: var(--ctp-mauve) !important; box-shadow: 0 0 0 0.2rem rgba(var(--bs-primary-rgb), 0.25) !important; }
    input::placeholder, textarea::placeholder { color: var(--ctp-overlay0) !important; }
    select option { background-color: var(--ctp-surface0) !important; color: var(--ctp-text) !important; }
    .form-check-input:checked { background-color: var(--ctp-green) !important; border-color: var(--ctp-green) !important; }
    .form-check-input[type=checkbox]:indeterminate { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; }
    .form-check-input:focus { box-shadow: 0 0 0 0.2rem rgba(var(--bs-primary-rgb), 0.25) !important; border-color: var(--ctp-mauve) !important; }
    .form-range::-webkit-slider-thumb { background-color: var(--ctp-mauve) !important; }
    .form-range::-moz-range-thumb { background-color: var(--ctp-mauve) !important; }
    .custom-switch-input:checked ~ .custom-switch-indicator { background: var(--ctp-green) !important; }
    .custom-control-input:checked ~ .custom-control-label:before { background-color: var(--ctp-green) !important; border-color: var(--ctp-green) !important; }
    .form-fieldset { background: var(--ctp-surface0) !important; border-color: var(--ctp-surface1) !important; }
    .form-help:hover, .form-help[aria-describedby] { background: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }

    /* Tables */
    .table, .table th, .table td, table thead, table th, table td { background-color: inherit !important; border-color: var(--ctp-surface0) !important; color: var(--ctp-text) !important; }
    .table-hover tbody tr:hover { background-color: var(--ctp-surface0) !important; }
    .file-item, .dir-item { border-bottom: 1px solid var(--ctp-surface0) !important; }

    /* SPA panel headers */
    body .side-panel-north, body .main-panel-north, [class*="panel-north"] { background-color: var(--ctp-mantle) !important; border-bottom: 1px solid var(--ctp-surface0) !important; color: var(--ctp-text) !important; }

    /* Nav pills */
    .nav.nav-pills { background-color: var(--ctp-mantle) !important; }
    .nav-pills .nav-link { color: var(--ctp-subtext0) !important; }
    .nav-pills .nav-link:hover { background-color: var(--ctp-surface0) !important; color: var(--ctp-text) !important; }
    .nav-pills .nav-link.active, .nav-pills .show > .nav-link { background-color: var(--ctp-lavender) !important; color: var(--ctp-crust) !important; }

    /* Nav tabs */
    .nav-tabs .nav-link { color: var(--ctp-subtext0) !important; }
    .nav-tabs .nav-link.active { color: var(--ctp-lavender) !important; border-bottom-color: var(--ctp-lavender) !important; background-color: transparent !important; }
    .nav-tabs { border-bottom-color: var(--ctp-surface0) !important; }
    .nav-tabs .nav-submenu .nav-item.active { color: var(--ctp-lavender) !important; }

    /* Nav active indicators (::before) */
    .nav-item::before, .nav-item.active::before, .nav-link::before, .nav-link.active::before,
    .side-nav .nav-item::before, .side-nav .nav-item.active::before,
    [class*="nav-item"]::before, [class*="nav-item"].active::before,
    [class*="nav-indicator"]::before, [class*="indicator-container"]::before,
    .nav-indicator-container::before, .nav .nav-indicator-container::before {
      background-color: var(--ctp-mauve) !important; background: var(--ctp-mauve) !important;
    }

    /* Context menu */
    .contextmenu, .context-menu, [class*="context-menu"] { background-color: var(--ctp-surface0) !important; border: 1px solid var(--ctp-surface1) !important; }
    .contextmenu li:hover, .context-menu li:hover, [class*="context-menu"] li:hover { background-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }

    /* Misc components */
    .link-primary { color: var(--ctp-mauve) !important; }
    .link-primary:hover { color: var(--ctp-lavender) !important; }
    .page-link { background-color: var(--ctp-surface0) !important; border-color: var(--ctp-surface1) !important; color: var(--ctp-text) !important; }
    .page-link:hover { background-color: var(--ctp-surface1) !important; color: var(--ctp-mauve) !important; }
    .page-item.active .page-link { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }
    .progress { background-color: var(--ctp-surface0) !important; }
    .progress-bar { background-color: var(--ctp-mauve) !important; }
    .list-group-item { background-color: var(--ctp-surface0) !important; border-color: var(--ctp-surface1) !important; color: var(--ctp-text) !important; }
    .list-group-item.active { color: var(--ctp-mauve) !important; background-color: rgba(var(--bs-primary-rgb), 0.1) !important; }
    .tag { background-color: var(--ctp-surface1) !important; color: var(--ctp-text) !important; }
    .tag-primary { background-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }
    .alert-success { background-color: rgba(var(--bs-primary-rgb), 0.05) !important; border-color: var(--ctp-green) !important; color: var(--ctp-green) !important; }
    .alert-danger, .alert-error { background-color: rgba(var(--bs-primary-rgb), 0.05) !important; border-color: var(--ctp-red) !important; color: var(--ctp-red) !important; }
    .alert-warning { background-color: rgba(var(--bs-primary-rgb), 0.05) !important; border-color: var(--ctp-yellow) !important; color: var(--ctp-yellow) !important; }
    .path-container, .breadcrumb { background-color: transparent !important; color: var(--ctp-subtext0) !important; }
    .breadcrumb a { color: var(--ctp-mauve) !important; }
    .toolbar, .dir-tool-bar, .operation-toolbar { background-color: var(--ctp-base) !important; border-bottom: 1px solid var(--ctp-surface0) !important; }
    .search-input, .search-container input { background-color: var(--ctp-surface0) !important; border-color: var(--ctp-surface1) !important; color: var(--ctp-text) !important; }
    .tooltip-inner { background-color: var(--ctp-surface0) !important; color: var(--ctp-text) !important; }
    ::-webkit-scrollbar { width: 8px; height: 8px; }
    ::-webkit-scrollbar-track { background: var(--ctp-mantle); }
    ::-webkit-scrollbar-thumb { background: var(--ctp-surface1); border-radius: 4px; }
    ::-webkit-scrollbar-thumb:hover { background: var(--ctp-surface2); }
    .spinner-border { color: var(--ctp-mauve) !important; }
    ::selection { background-color: rgba(var(--bs-primary-rgb), 0.3); color: var(--ctp-text); }
    .table-calendar-link:before { background: var(--ctp-mauve) !important; }
    .table-calendar-link:hover { background: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }

    /* Icons — color variety */
    .sf-icon, .op-icon, svg.icon { color: var(--ctp-subtext0) !important; }
    .sf-icon:hover, .op-icon:hover { color: var(--ctp-peach) !important; }
    .sf3-font-folder, [class*="icon-folder"], .dir-icon { color: var(--ctp-blue) !important; }
    .sf3-font-file, [class*="icon-file"] { color: var(--ctp-lavender) !important; }
    .sf3-font-star, [class*="icon-star"], .star, .starred { color: var(--ctp-peach) !important; }
    .sf3-font-share, [class*="icon-share"] { color: var(--ctp-blue) !important; }
    .sf3-font-bell, [class*="icon-bell"] { color: var(--ctp-peach) !important; }
    .sf3-font-library, [class*="icon-lib"] { color: var(--ctp-blue) !important; }
    .sf3-font-upload, .sf3-font-download, [class*="icon-upload"], [class*="icon-download"] { color: var(--ctp-green) !important; }
    .sf3-font-delete, .sf3-font-trash, [class*="icon-delete"], [class*="icon-trash"] { color: var(--ctp-red) !important; }
    .sf3-font-settings, [class*="icon-settings"], [class*="icon-gear"] { color: var(--ctp-overlay1) !important; }

    /* Footer */
    footer, .main-panel-south { background-color: var(--ctp-mantle) !important; border-top: 1px solid var(--ctp-surface0) !important; color: var(--ctp-subtext0) !important; }
    pre, code { background-color: var(--ctp-surface0) !important; color: var(--ctp-text) !important; border-color: var(--ctp-surface1) !important; }
    .text-muted { color: var(--ctp-overlay0) !important; }
    h1, h2, h3, h4, h5, h6, p, span, label, div, li, th, td { color: inherit; }
    .hl { background-color: rgba(var(--bs-primary-rgb), 0.1) !important; }

    /* === SYSTEM ADMIN PAGE === */
    #right-panel, #main, #base { background-color: var(--ctp-base) !important; color: var(--ctp-text) !important; }
    #header { background-color: var(--ctp-mantle) !important; border-bottom: 1px solid var(--ctp-surface1) !important; }
    #logo, #logo a { background-color: var(--ctp-mantle) !important; }
    #wrapper { background-color: var(--ctp-base) !important; color: var(--ctp-text) !important; }
    #right-panel .hd { border-bottom-color: var(--ctp-surface1) !important; }
    #right-panel .hd .tab { color: var(--ctp-subtext0) !important; }
    #right-panel .hd .tab:hover, #right-panel .hd .tab.current { color: var(--ctp-mauve) !important; border-bottom-color: var(--ctp-mauve) !important; }
    .side-tabnav-tabs { background-color: var(--ctp-mantle) !important; }
    .side-tabnav-tabs .tab a { color: var(--ctp-subtext0) !important; }
    .side-tabnav-tabs .tab a:hover, .side-tabnav-tabs .tab-cur a { color: var(--ctp-mauve) !important; background-color: var(--ctp-surface0) !important; }
    .account-popup, .account-popup .sf-popover-con { background-color: var(--ctp-surface0) !important; }
    .account-popup a.item { color: var(--ctp-text) !important; }
    .account-popup a.item:hover { background-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }
    #lang-context-selector, #lang-context-selector .sf-popover-con { background-color: var(--ctp-surface0) !important; }
    #lang-context, #lang-context:hover { color: var(--ctp-text) !important; }
    .narrow-panel, .wide-panel, .tfa-panel { background-color: var(--ctp-surface0) !important; color: var(--ctp-text) !important; }
    .narrow-panel h2, .narrow-panel h3, .wide-panel h2, .wide-panel h3 { color: var(--ctp-text) !important; }

    /* === LOGIN PAGE === */
    .login-panel, #login-form { background-color: rgba(var(--bs-primary-rgb), 0.03) !important; border: 1px solid var(--ctp-surface1) !important; border-radius: 8px !important; backdrop-filter: blur(10px) !important; }
    .login-panel h1, .login-panel h2, .login-panel .login-title, .login-panel-hd { color: var(--ctp-text) !important; }
    .login-panel .login-btn, .login-panel .submit-btn { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }
    .login-panel .login-btn:hover, .login-panel .submit-btn:hover { background-color: var(--ctp-lavender) !important; border-color: var(--ctp-lavender) !important; }
  '';

in
{
  options.wagou.branding = {
    palette.mocha = mkOption {
      type = types.attrs;
      default = mocha;
      readOnly = true;
      description = "Catppuccin Mocha palette (dark mode)";
    };
    palette.latte = mkOption {
      type = types.attrs;
      default = latte;
      readOnly = true;
      description = "Catppuccin Latte palette (light mode)";
    };
    accent = mkOption {
      type = types.attrs;
      default = {
        light = latte.mauve;
        dark = mocha.mauve;
      };
      readOnly = true;
      description = "Primary accent colors for light/dark mode";
    };
    gradient = mkOption {
      type = types.attrs;
      default = gradient;
      readOnly = true;
      description = "Sunset gradient colors (start, mid, end)";
    };
    favicon = mkOption {
      type = types.path;
      default = favicon;
      readOnly = true;
      description = "Synthwave sunset favicon SVG";
    };
    backgrounds = mkOption {
      type = types.attrs;
      default = backgrounds;
      readOnly = true;
      description = "Available background images";
    };
    loginBackground = mkOption {
      type = types.path;
      default = backgrounds.city;
      readOnly = true;
      description = "Default login page background image";
    };
    mkLogo = mkOption {
      type = types.functionTo types.package;
      default = mkLogo;
      readOnly = true;
      description = "Function: service name -> SVG logo derivation";
    };
    css.seafile = mkOption {
      type = types.package;
      default = seafileCss;
      readOnly = true;
      description = "Complete Seafile Catppuccin CSS file";
    };
    css.authentik = mkOption {
      type = types.str;
      default = authentikCss;
      readOnly = true;
      description = "Authentik custom CSS string (for blueprint injection)";
    };
  };
}
