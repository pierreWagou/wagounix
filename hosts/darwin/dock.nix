{
  lib,
  config,
  host,
  ...
}:

let
  cfg = config.wagounix.dock;
in
{

  options.wagounix.dock = {
    leadingApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/Applications/Thunderbird.app/"
        "/Applications/Zen.app/"
      ];
      description = "Dock apps placed before host-specific entries.";
    };

    middleApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Host-specific dock apps inserted between the shared app groups.";
    };

    trailingApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/Applications/Visual Studio Code.app/"
        "/Applications/Ghostty.app/"
        "${host.restrictedAppDir}/Spotify.app/"
      ];
      description = "Dock apps placed after host-specific entries.";
    };
  };

  config.system.defaults.dock.persistent-apps = cfg.leadingApps ++ cfg.middleApps ++ cfg.trailingApps;
}
