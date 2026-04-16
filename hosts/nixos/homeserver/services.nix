{ pkgs, ... }:

{
  # Server services — add your services here.
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
