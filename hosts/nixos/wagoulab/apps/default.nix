_: {

  # User-built applications managed by Coolify.
  # Coolify handles container lifecycle, rolling deploys, and PR preview environments.
  # NixOS manages: the Coolify service itself, the Podman Docker-compatible socket, and secrets.
  imports = [
    ./coolify.nix
  ];
}
