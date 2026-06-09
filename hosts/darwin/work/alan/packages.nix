{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    awscli2
    _1password-cli
  ];
}
