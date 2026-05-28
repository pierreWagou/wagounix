{
  config,
  pkgs,
  host,
  ...
}:

let
  inherit (config.virtualisation.quadlet) networks containers;

  # --- Branding Assets ---

  # Catppuccin Mocha theme with Mauve accent
  customCss = pkgs.writeText "seafile-custom.css" ''
    /* Catppuccin Theme for Seafile v13
       Light: Catppuccin Latte | Dark: Catppuccin Mocha
       Accent: Mauve
       https://catppuccin.com */

    /* === LIGHT MODE: Catppuccin Latte === */
    :root,
    [data-bs-theme=light] {
      --ctp-base: #eff1f5;
      --ctp-mantle: #e6e9ef;
      --ctp-crust: #dce0e8;
      --ctp-surface0: #ccd0da;
      --ctp-surface1: #bcc0cc;
      --ctp-surface2: #acb0be;
      --ctp-overlay0: #9ca0b0;
      --ctp-overlay1: #8c8fa1;
      --ctp-text: #4c4f69;
      --ctp-subtext0: #6c6f85;
      --ctp-subtext1: #5c5f77;
      --ctp-mauve: #8839ef;
      --ctp-lavender: #7287fd;
      --ctp-red: #d20f39;
      --ctp-green: #40a02b;
      --ctp-yellow: #df8e1d;
      --ctp-peach: #fe640b;
      --ctp-blue: #1e66f5;
      --bs-body-color: #4c4f69;
      --bs-body-secondary-color: #6c6f85;
      --bs-body-bg: #eff1f5;
      --bs-body-secondary-bg: #e6e9ef;
      --bs-emphasis-color: #4c4f69;
      --bs-border-color: #ccd0da;
      --bs-border-secondary-color: #ccd0da;
      --bs-border-tertiary-color: #dce0e8;
      --bs-secondary-color: #5c5f77;
      --bs-tertiary-color: #6c6f85;
      --bs-header-bg: #e6e9ef;
      --bs-header-secondary-bg: #e6e9ef;
      --bs-header-tertiary-bg: #dce0e8;
      --bs-toolbar-bg: #eff1f5;
      --bs-toolbar-secondary-bg: #e6e9ef;
      --bs-nav-hover-bg: #dce0e8;
      --bs-nav-active-bg: #ccd0da;
      --bs-wiki-nav-hover-bg: #dce0e8;
      --bs-wiki-nav-active-bg: #ccd0da;
      --bs-th-bg: #e6e9ef;
      --bs-th-secondary-bg: #e6e9ef;
      --bs-th-tertiary-bg: #eff1f5;
      --bs-th-quartus-bg: #ccd0da;
      --bs-th-fifth-bg: #bcc0cc;
      --bs-tr-active-bg: #dce0e8;
      --bs-tr-active-secondary-bg: rgba(136, 57, 239, 0.1);
      --bs-tr-hover-bg: #e6e9ef;
      --bs-icon-color: #6c6f85;
      --bs-icon-secondary-color: #6c6f85;
      --bs-icon-tertiary-color: #9ca0b0;
      --bs-icon-hover-color: #8839ef;
      --bs-hover-bg: #e6e9ef;
      --bs-hover-secondary-bg: #dce0e8;
      --bs-hover-tertiary-bg: #ccd0da;
      --bs-bg-color: #e6e9ef;
      --bs-bg-secondary-color: #dce0e8;
      --bs-dropdown-link-bg: #8839ef;
      --bs-dropdown-secondary-bg: #e6e9ef;
      --bs-dropdown-tertiary-bg: #e6e9ef;
      --bs-popover-bg: #eff1f5;
      --bs-placeholder-color: #9ca0b0;
      --bs-primary: #8839ef;
      --bs-primary-rgb: 136, 57, 239;
      --bs-link-color: #8839ef;
      --bs-link-hover-color: #7287fd;
    }

    /* === DARK MODE: Catppuccin Mocha === */
    [data-bs-theme=dark] {
      --ctp-base: #1e1e2e;
      --ctp-mantle: #181825;
      --ctp-crust: #11111b;
      --ctp-surface0: #313244;
      --ctp-surface1: #45475a;
      --ctp-surface2: #585b70;
      --ctp-overlay0: #6c7086;
      --ctp-overlay1: #7f849c;
      --ctp-text: #cdd6f4;
      --ctp-subtext0: #a6adc8;
      --ctp-subtext1: #bac2de;
      --ctp-mauve: #cba6f7;
      --ctp-lavender: #b4befe;
      --ctp-red: #f38ba8;
      --ctp-green: #a6e3a1;
      --ctp-yellow: #f9e2af;
      --ctp-peach: #fab387;
      --ctp-blue: #89b4fa;
      --bs-body-color: #cdd6f4;
      --bs-body-secondary-color: #a6adc8;
      --bs-body-bg: #1e1e2e;
      --bs-body-secondary-bg: #313244;
      --bs-emphasis-color: #cdd6f4;
      --bs-border-color: #45475a;
      --bs-border-secondary-color: #45475a;
      --bs-border-tertiary-color: #313244;
      --bs-secondary-color: #bac2de;
      --bs-tertiary-color: #a6adc8;
      --bs-header-bg: #181825;
      --bs-header-secondary-bg: #181825;
      --bs-header-tertiary-bg: #11111b;
      --bs-toolbar-bg: #1e1e2e;
      --bs-toolbar-secondary-bg: #181825;
      --bs-nav-hover-bg: #313244;
      --bs-nav-active-bg: #313244;
      --bs-wiki-nav-hover-bg: #313244;
      --bs-wiki-nav-active-bg: #45475a;
      --bs-th-bg: #181825;
      --bs-th-secondary-bg: #181825;
      --bs-th-tertiary-bg: #1e1e2e;
      --bs-th-quartus-bg: #313244;
      --bs-th-fifth-bg: #45475a;
      --bs-tr-active-bg: #313244;
      --bs-tr-active-secondary-bg: rgba(203, 166, 247, 0.15);
      --bs-tr-hover-bg: #313244;
      --bs-icon-color: #a6adc8;
      --bs-icon-secondary-color: #a6adc8;
      --bs-icon-tertiary-color: #6c7086;
      --bs-icon-hover-color: #cba6f7;
      --bs-hover-bg: #313244;
      --bs-hover-secondary-bg: #45475a;
      --bs-hover-tertiary-bg: #585b70;
      --bs-bg-color: #313244;
      --bs-bg-secondary-color: #181825;
      --bs-dropdown-link-bg: #cba6f7;
      --bs-dropdown-secondary-bg: #313244;
      --bs-dropdown-tertiary-bg: #313244;
      --bs-popover-bg: #313244;
      --bs-placeholder-color: #6c7086;
      --bs-primary: #cba6f7;
      --bs-primary-rgb: 203, 166, 247;
      --bs-link-color: #cba6f7;
      --bs-link-hover-color: #b4befe;
      color-scheme: dark;
    }

    /* === STRUCTURAL OVERRIDES (both themes via variables) === */

    body, .page, .page-main, .page-content, .bg-white,
    #wrapper, .main-panel, .main-panel-center, .main-con,
    .page-single, .container, .container-fluid {
      background-color: var(--ctp-base) !important;
      color: var(--ctp-text) !important;
    }

    .aside { background-color: var(--ctp-mantle) !important; border-color: var(--ctp-surface1) !important; }

    .header, .top-header, .main-panel-north, #header {
      background-color: var(--ctp-mantle) !important;
      border-bottom: 1px solid var(--ctp-surface0) !important;
    }

    .side-panel, .side-nav, .side-nav-con, .left-panel {
      background-color: var(--ctp-mantle) !important;
      border-right: 1px solid var(--ctp-surface0) !important;
    }

    .side-nav .nav-item, .side-nav a, .side-panel a { color: var(--ctp-subtext0) !important; }
    .side-nav .nav-item:hover, .side-nav a:hover, .side-panel a:hover { color: var(--ctp-text) !important; background-color: var(--ctp-surface0) !important; }
    .side-nav .nav-item.active, .side-nav .nav-item.active a { color: var(--ctp-mauve) !important; background-color: var(--ctp-surface0) !important; }

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
    .dropdown-item:hover, .dropdown-item:focus { background-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }
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
    .form-check-input:checked { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; }
    .form-check-input[type=checkbox]:indeterminate { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; }
    .form-check-input:focus { box-shadow: 0 0 0 0.2rem rgba(var(--bs-primary-rgb), 0.25) !important; border-color: var(--ctp-mauve) !important; }
    .form-range::-webkit-slider-thumb { background-color: var(--ctp-mauve) !important; }
    .form-range::-moz-range-thumb { background-color: var(--ctp-mauve) !important; }
    .custom-switch-input:checked ~ .custom-switch-indicator { background: var(--ctp-mauve) !important; }
    .custom-control-input:checked ~ .custom-control-label:before { background-color: var(--ctp-mauve) !important; border-color: var(--ctp-mauve) !important; }
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
    .nav-pills .nav-link.active, .nav-pills .show > .nav-link { background-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }

    /* Nav tabs */
    .nav-tabs .nav-link { color: var(--ctp-subtext0) !important; }
    .nav-tabs .nav-link.active { color: var(--ctp-mauve) !important; border-bottom-color: var(--ctp-mauve) !important; background-color: transparent !important; }
    .nav-tabs { border-bottom-color: var(--ctp-surface0) !important; }
    .nav-tabs .nav-submenu .nav-item.active { color: var(--ctp-mauve) !important; }

    /* Nav active indicators (::before) */
    .nav-item::before, .nav-item.active::before, .nav-link::before, .nav-link.active::before,
    .side-nav .nav-item::before, .side-nav .nav-item.active::before,
    [class*="nav-item"]::before, [class*="nav-item"].active::before,
    [class*="nav-indicator"]::before, [class*="indicator-container"]::before,
    .nav-indicator-container::before, .nav .nav-indicator-container::before {
      background-color: var(--ctp-mauve) !important;
      background: var(--ctp-mauve) !important;
    }

    /* Context menu */
    .contextmenu, .context-menu, [class*="context-menu"] { background-color: var(--ctp-surface0) !important; border: 1px solid var(--ctp-surface1) !important; }
    .contextmenu li:hover, .context-menu li:hover, [class*="context-menu"] li:hover { background-color: var(--ctp-mauve) !important; color: var(--ctp-crust) !important; }

    /* Misc */
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
    .sf-icon, .op-icon, svg.icon { color: var(--ctp-subtext0) !important; }
    .sf-icon:hover, .op-icon:hover { color: var(--ctp-mauve) !important; }

    /* Color variety — use other Catppuccin palette colors for visual interest */
    /* Folder icons: Blue */
    .sf3-font-folder, [class*="icon-folder"], .dir-icon { color: var(--ctp-blue) !important; }
    /* File icons: Lavender */
    .sf3-font-file, [class*="icon-file"] { color: var(--ctp-lavender) !important; }
    /* Star/favorite: Peach */
    .sf3-font-star, [class*="icon-star"], .star { color: var(--ctp-peach) !important; }
    .starred { color: var(--ctp-peach) !important; }
    /* Share icon: Blue */
    .sf3-font-share, [class*="icon-share"] { color: var(--ctp-blue) !important; }
    /* Notifications bell: Peach */
    .sf3-font-bell, [class*="icon-bell"], [class*="notification"] .sf3-font { color: var(--ctp-peach) !important; }
    /* User/avatar accent ring */
    .avatar-ring, [class*="avatar"] { border-color: var(--ctp-lavender) !important; }
    /* Library/repo icons: Blue */
    .sf3-font-library, [class*="icon-lib"] { color: var(--ctp-blue) !important; }
    /* Upload/download: Green */
    .sf3-font-upload, .sf3-font-download, [class*="icon-upload"], [class*="icon-download"] { color: var(--ctp-green) !important; }
    /* Delete/trash: Red */
    .sf3-font-delete, .sf3-font-trash, [class*="icon-delete"], [class*="icon-trash"] { color: var(--ctp-red) !important; }
    /* Settings gear: Overlay1 (neutral but distinct) */
    .sf3-font-settings, [class*="icon-settings"], [class*="icon-gear"] { color: var(--ctp-overlay1) !important; }

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

  # SVG logo: favicon icon + "WAGOU DISK" text
  logoSvg = pkgs.writeText "seafile-logo.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 250 40" width="250" height="40">
      <defs>
        <filter id="neon-glow" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="1.5" result="blur"/>
          <feColorMatrix in="blur" type="matrix"
            values="0 0 0 0 0.796
                    0 0 0 0 0.651
                    0 0 0 0 0.969
                    0 0 0 0.6 0" result="glow"/>
          <feMerge>
            <feMergeNode in="glow"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>
      <!-- Favicon icon -->
      <rect x="2" y="4" width="32" height="32" rx="6" fill="#1e1e2e"/>
      <rect x="3" y="5" width="30" height="30" rx="5" fill="none" stroke="#cba6f7" stroke-width="1.5" opacity="0.5"/>
      <text x="18" y="26"
            font-family="'JetBrains Mono', monospace"
            font-size="13"
            font-weight="700"
            fill="#cba6f7"
            text-anchor="middle">WD</text>
      <!-- Text -->
      <text x="44" y="27"
            font-family="'JetBrains Mono', 'Fira Code', 'SF Mono', monospace"
            font-size="18"
            font-weight="700"
            letter-spacing="2"
            fill="#cba6f7"
            filter="url(#neon-glow)">WAGOU DISK</text>
    </svg>
  '';

  # Favicon: compact "WD" icon with Catppuccin styling
  faviconSvg = pkgs.writeText "seafile-favicon.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
      <rect width="32" height="32" rx="6" fill="#1e1e2e"/>
      <rect x="1" y="1" width="30" height="30" rx="5" fill="none" stroke="#cba6f7" stroke-width="1.5" opacity="0.5"/>
      <text x="16" y="22"
            font-family="'JetBrains Mono', monospace"
            font-size="13"
            font-weight="700"
            fill="#cba6f7"
            text-anchor="middle">WD</text>
    </svg>
  '';

  # Login background — reuse homepage ocean image
  loginBg = ./homepage-images/ocean.jpg;
in
{
  # Seafile-internal network for DB, Redis, and SeaDoc (not exposed to Traefik)
  virtualisation.quadlet.networks.seafile-internal = { };

  # Complete seahub_settings.py rendered by sops-nix
  # Deploy with: sudo seafile-deploy
  sops.templates."seahub_settings.py" = {
    content = builtins.concatStringsSep "\n" [
      "SECRET_KEY = '${config.sops.placeholder.seafile-secret-key}'"
      "SERVICE_URL = 'https://disk.${host.domain}'"
      "FILE_SERVER_ROOT = 'https://disk.${host.domain}/seafhttp'"
      "TIME_ZONE = '${host.timezone}'"
      ""
      "CSRF_TRUSTED_ORIGINS = ['https://disk.${host.domain}']"
      ""
      "# Branding"
      "SITE_NAME = 'Wagou Disk'"
      "SITE_TITLE = 'Wagou Disk'"
      "LOGO_PATH = 'custom/logo.svg'"
      "LOGO_WIDTH = 250"
      "LOGO_HEIGHT = 40"
      "FAVICON_PATH = 'custom/favicon.svg'"
      "LOGIN_BG_IMAGE_PATH = 'custom/login-bg.jpg'"
      "BRANDING_CSS = 'custom/custom.css'"
      "ENABLE_SETTINGS_VIA_WEB = False"
      ""
      "# OAuth/OIDC via Authentik"
      "ENABLE_OAUTH = True"
      "OAUTH_CREATE_UNKNOWN_USER = True"
      "OAUTH_ACTIVATE_USER_AFTER_CREATION = True"
      "OAUTH_CLIENT_ID = 'seafile'"
      "OAUTH_CLIENT_SECRET = '${config.sops.placeholder.seafile-oauth-client-secret}'"
      "OAUTH_REDIRECT_URL = 'https://disk.${host.domain}/oauth/callback/'"
      "OAUTH_PROVIDER_DOMAIN = 'https://cipher.${host.domain}'"
      "OAUTH_AUTHORIZATION_URL = 'https://cipher.${host.domain}/application/o/authorize/'"
      "OAUTH_TOKEN_URL = 'https://cipher.${host.domain}/application/o/token/'"
      "OAUTH_USER_INFO_URL = 'https://cipher.${host.domain}/application/o/userinfo/'"
      "OAUTH_SCOPE = ['openid', 'profile', 'email']"
      "OAUTH_ATTRIBUTE_MAP = {"
      "    'email': (True, 'email'),"
      "    'name': (False, 'name'),"
      "    'sub': (True, 'uid'),"
      "}"
      ""
      "# SSO via system browser for desktop/mobile clients"
      "CLIENT_SSO_VIA_LOCAL_BROWSER = True"
      ""
      "# SeaDoc"
      "ENABLE_SEADOC = True"
    ];
  };

  virtualisation.quadlet.containers = {
    seafile = {
      containerConfig = {
        image = "docker.io/seafileltd/seafile-mc:13.0-latest";
        noNewPrivileges = true;
        networks = [
          networks.proxy.ref
          networks.seafile-internal.ref
        ];
        volumes = [
          "/var/lib/seafile:/shared"
        ];
        environments = {
          SEAFILE_MYSQL_DB_HOST = "seafile-db";
          SEAFILE_MYSQL_DB_PORT = "3306";
          SEAFILE_MYSQL_DB_USER = "seafile";
          SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
          SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
          SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";
          TIME_ZONE = host.timezone;
          SEAFILE_SERVER_HOSTNAME = "disk.${host.domain}";
          SEAFILE_SERVER_PROTOCOL = "https";
          CACHE_PROVIDER = "redis";
          REDIS_HOST = "seafile-redis";
          REDIS_PORT = "6379";
          ENABLE_SEADOC = "true";
          INIT_SEAFILE_ADMIN_EMAIL = "pierre.romon@gmail.com";
          INIT_SEAFILE_ADMIN_PASSWORD = "changeme";
        };
        environmentFiles = [ config.sops.templates."seafile.env".path ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.seafile.rule" = "Host(`disk.${host.domain}`)";
          "traefik.http.routers.seafile.entrypoints" = "websecure";
          "traefik.http.routers.seafile.tls" = "true";
          "traefik.http.routers.seafile.middlewares" = "secure-headers@file";
          "traefik.http.services.seafile.loadbalancer.server.port" = "80";
        };
      };
      unitConfig = {
        Requires = [
          containers.seafile-db.ref
          containers.seafile-redis.ref
        ];
        After = [
          containers.seafile-db.ref
          containers.seafile-redis.ref
        ];
      };
    };

    seafile-db = {
      containerConfig = {
        image = "docker.io/library/mariadb:10.11";
        noNewPrivileges = true;
        networks = [ networks.seafile-internal.ref ];
        volumes = [ "/var/lib/seafile-mysql:/var/lib/mysql" ];
        environments = {
          MARIADB_AUTO_UPGRADE = "1";
          MYSQL_LOG_CONSOLE = "true";
        };
        environmentFiles = [ config.sops.templates."seafile-db.env".path ];
      };
    };

    seafile-redis = {
      containerConfig = {
        image = "docker.io/valkey/valkey:9.1.0";
        noNewPrivileges = true;
        networks = [ networks.seafile-internal.ref ];
        exec = [
          "--save"
          "60"
          "1"
          "--loglevel"
          "warning"
        ];
        volumes = [ "/var/lib/seafile-redis:/data" ];
      };
    };

    seadoc = {
      containerConfig = {
        image = "docker.io/seafileltd/sdoc-server:2.0-latest";
        noNewPrivileges = true;
        networks = [ networks.seafile-internal.ref ];
        volumes = [ "/var/lib/seadoc:/shared" ];
        environments = {
          SEAFILE_SERVER_HOSTNAME = "disk.${host.domain}";
          SEAFILE_SERVER_PROTOCOL = "https";
        };
        environmentFiles = [ config.sops.templates."seafile.env".path ];
      };
      unitConfig = {
        Requires = [ containers.seafile.ref ];
        After = [ containers.seafile.ref ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/seafile 0755 root root -"
    "d /var/lib/seafile-mysql 0755 root root -"
    "d /var/lib/seafile-redis 0750 999 999 -"
    "Z /var/lib/seafile-redis 0750 999 999 -"
    "d /var/lib/seadoc 0755 root root -"
    # Branding assets directory
    "d /var/lib/seafile/seafile/seahub-data/custom 0755 root root -"
  ];

  # Idempotent script to deploy seahub config + branding
  # Run: sudo seafile-deploy
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "seafile-deploy" ''
      SETTINGS="/var/lib/seafile/seafile/conf/seahub_settings.py"
      CUSTOM="/var/lib/seafile/seafile/seahub-data/custom"
      if [ ! -d "/var/lib/seafile/seafile/conf" ]; then
        echo "Error: Seafile conf directory not found. Has Seafile been initialized?"
        exit 1
      fi
      # Deploy seahub config
      cp ${config.sops.templates."seahub_settings.py".path} "$SETTINGS"
      chmod 644 "$SETTINGS"
      # Deploy branding assets
      mkdir -p "$CUSTOM"
      cp ${customCss} "$CUSTOM/custom.css"
      cp ${logoSvg} "$CUSTOM/logo.svg"
      cp ${faviconSvg} "$CUSTOM/favicon.svg"
      cp ${loginBg} "$CUSTOM/login-bg.jpg"
      chmod 644 "$CUSTOM"/*
      # Restart seahub
      podman exec seafile /opt/seafile/seafile-server-latest/seahub.sh restart || \
        podman exec seafile /opt/seafile/seafile-server-latest/seahub.sh start
      echo "Done. Seahub config + branding deployed."
    '')
  ];
}
