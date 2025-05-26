{ inputs, config, lib, pkgs, ... }: {

  imports = [
    inputs.sops-nix.darwinModules.sops
  ];

  sops = {
    defaultSopsFile = ./secrets/example.yaml;
  }