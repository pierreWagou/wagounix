{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    databricks-cli
  ];
}
