{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    opencode
    databricks-cli
  ];
}
