_: {
  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    defaults = {
      CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            "60" = {
              # disable ^+Space (prev input source)
              enabled = false;
            };
            "61" = {
              # disable ^+Opt+Space (next input source)
              enabled = false;
            };
            "64" = {
              # disable Cmd+Space (Spotlight)
              enabled = false;
            };
            "65" = {
              # keep Cmd+Opt+Space (Finder search)
              enabled = true;
            };
          };
        };
      };
    };
  };
}
