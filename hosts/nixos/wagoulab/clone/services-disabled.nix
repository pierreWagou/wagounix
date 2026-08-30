{ config, lib, ... }:

{
  # Disable all container services on wagou-clone by default.
  # The backup machine sits idle — services are started manually during failover.
  systemd.services = lib.mapAttrs (_: _: {
    wantedBy = lib.mkForce [ ];
  }) config.virtualisation.quadlet.containers;
}
