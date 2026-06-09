{
  lib,
  config,
  ...
}:

let
  cfg = config.wagou.dock;
in
{

  options.wagou.dock = {
    communication = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/Applications/Thunderbird.app/" ];
      description = "Communication apps in the dock.";
    };

    browser = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/Applications/Zen.app/" ];
      description = "Browser apps in the dock.";
    };

    development = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/Applications/Visual Studio Code.app/"
        "/Applications/Ghostty.app/"
      ];
      description = "Development apps in the dock.";
    };

    others = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/Applications/Spotify.app/" ];
      description = "Other apps in the dock.";
    };
  };

  config.system.defaults.dock.persistent-apps =
    cfg.communication ++ cfg.browser ++ cfg.development ++ cfg.others;
}
