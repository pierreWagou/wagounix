{ config, lib, ... }:

{
  # Warm standby: services stay off until manual start at failover.
  systemd.services = lib.mapAttrs (_: _: {
    wantedBy = lib.mkForce [ ];
  }) config.virtualisation.quadlet.containers;
}
