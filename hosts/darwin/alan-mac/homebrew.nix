{ host, lib, ... }:
{
  homebrew = {
    brews = [
      "portless"
    ];
    casks = [
      "1password"
      "android-studio"
      "claude"
      "figma"
      "linear"
      "notion"
      "slack"
    ];
  };

  # Work MDM reinstalls apps as root, breaking brew upgrade (chmod EPERM).
  # Re-assert ownership pre-homebrew step, as root; must never fail the switch.
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    for APP in \
      "/Applications/Visual Studio Code.app" \
      "/Applications/Notion.app" \
      "/Applications/Linear.app"
    do
      if [ -d "$APP" ] && [ "$(/usr/bin/stat -f %Su "$APP")" != "${host.username}" ]; then
        echo "Ensuring user ownership of $APP for Homebrew..." >&2
        /usr/sbin/chown -R "${host.username}:staff" "$APP" || true
        /usr/bin/chflags -R nouchg "$APP" || true
      fi
    done
  '';
}
