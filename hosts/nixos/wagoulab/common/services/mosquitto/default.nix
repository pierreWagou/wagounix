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

  # Native service, not a container, so secrets never land in the Nix store.
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
          homeassistant = {
            passwordFile = config.sops.secrets.mqtt-ha-password.path;
            acl = [ "readwrite #" ];
          };
          sofabaton = {
            passwordFile = config.sops.secrets.mqtt-sofabaton-password.path;
            acl = [ "readwrite #" ];
          };
        };
      }
    ];
  };
}
