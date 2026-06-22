{ ... }:
{
  imports = [
    ./homebrew.nix
    ./packages.nix
  ];

  wagou.dock.communication = [
    "/Applications/Thunderbird.app/"
    "/Applications/Slack.app/"
  ];

  wagou.dock.development = [
    "/Applications/Ghostty.app/"
    "/Applications/Notion.app/"
  ];
}
