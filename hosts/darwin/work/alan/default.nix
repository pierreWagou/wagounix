{ ... }:
{
  imports = [
    ./homebrew.nix
    ./packages.nix
  ];

  wagounix.dock.communication = [
    "/Applications/Thunderbird.app/"
    "/Applications/Slack.app/"
  ];
}
