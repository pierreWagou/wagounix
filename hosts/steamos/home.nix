{ pkgs, host, ... }:

{
  home = {
    inherit (host) username;
    homeDirectory = host.homeDir;
    # Pinned at creation — do not bump on updates, only for a fresh setup.
    stateVersion = "25.11";
  };

  nixpkgs.config.allowUnfree = true;

  # Packages only — the full wagounix common set, synced with
  # `home-manager switch --flake .#deck@steamos`.
  # Dotfiles stay with chezmoi (repo convention: no home-manager dotfiles).
  home.packages = import ../common/package-list.nix { inherit pkgs; };

  programs.home-manager.enable = true;
}
