{ ... }: {

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  system.defaults = {
    CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "60" = {
            # Disable '^ + Space' for selecting the previous input source
            enabled = false;
          };
          "61" = {
            # Disable '^ + Option + Space' for selecting the next input source
            enabled = false;
          };
          # Disable 'Cmd + Space' for Spotlight Search
          "64" = {
            enabled = false;
          };
          # Disable 'Cmd + Alt + Space' for Finder search window
          "65" = {
            # Set to false to disable
            enabled = true;
          };
        };
      };
    };
  };
}