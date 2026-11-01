{ host, lib, ... }:
{
  homebrew = {
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

  # Work MDM periodically reinstalls some apps as root, which breaks
  # `brew upgrade` (chmod EPERM on root-owned files). Re-assert user
  # ownership here: extraActivation runs before the homebrew step.
  # Activation runs as root, so no sudo needed. Never fails the switch.
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
