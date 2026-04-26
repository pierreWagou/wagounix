{ host, ... }:

{
  services.home-assistant = {
    enable = true;
    openFirewall = false;

    extraComponents = [
      # Required for onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Fast zlib compression
      "isal"
    ];

    config = {
      default_config = { };

      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Europe/Paris";
        external_url = "https://home.${host.domain}";
        internal_url = "https://home.${host.domain}";
      };

      http = {
        server_host = "127.0.0.1";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };

      # Allow UI-managed automations, scenes, and scripts
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
    };
  };
}
