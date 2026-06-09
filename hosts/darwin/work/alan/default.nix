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
}
