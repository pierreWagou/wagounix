{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    _1password-cli
    awscli2
    gitleaks
    maestro
    slack-cli
  ];
}
