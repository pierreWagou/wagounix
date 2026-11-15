{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  # Packages for all machines (including wagoulab).
  # The list itself lives in ./package-list.nix so the SteamOS
  # home-manager config can reuse the exact same set.
  environment.systemPackages = import ./package-list.nix { inherit pkgs; };
}
