{
  config,
  host,
  ...
}:

{
  sops.secrets = {
    mqtt-ha-password = {
      sopsFile = ./secrets.yaml;
      mode = "0400";
    };
    mqtt-sofabaton-password = {
      sopsFile = ./secrets.yaml;
      mode = "0400";
    };
  };

  # LAN-only MQTT broker shared by Home Assistant and the Sofabaton X2 hub
  # (HTTP delivery works without it; MQTT unlocks the X2-only Wifi Command
  # delivery plus retained activity state in the Sofabaton X integration).
  # Native service instead of a container: password files ride along as
  # systemd credentials, so no secret material ever lands in the Nix store.
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = host.serverIP;
        port = 1883;
        settings = {
          allow_anonymous = false;
        };
        users = {
          # Used by Home Assistant's MQTT integration (wired via secrets.yaml).
          homeassistant = {
            passwordFile = config.sops.secrets.mqtt-ha-password.path;
            # Broad by design: the integration manages its own press/state
            # topics (e.g. activity/<MAC>/activity_control_up). Tighten to
            # observed topics once the X2 is pointed at this broker.
            acl = [ "readwrite #" ];
          };
          # Entered once in the Sofabaton app / Control Panel hub settings.
          sofabaton = {
            passwordFile = config.sops.secrets.mqtt-sofabaton-password.path;
            acl = [ "readwrite #" ];
          };
        };
      }
    ];
  };
}
