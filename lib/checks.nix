{
  self,
  nixpkgs,
  git-hooks,
  systems,
}:
nixpkgs.lib.genAttrs systems (
  system:
  let
    pre-commit-check = git-hooks.lib.${system}.run {
      src = self;
      hooks = {
        nixfmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
      };
    };

    darwinChecks = nixpkgs.lib.mapAttrs' (name: cfg: nixpkgs.lib.nameValuePair name cfg.system) (
      nixpkgs.lib.filterAttrs (
        _: cfg: cfg.pkgs.stdenv.hostPlatform.system == system
      ) self.darwinConfigurations
    );

    nixosChecks =
      nixpkgs.lib.mapAttrs' (name: cfg: nixpkgs.lib.nameValuePair name cfg.config.system.build.toplevel)
        (
          nixpkgs.lib.filterAttrs (
            _: cfg: cfg.pkgs.stdenv.hostPlatform.system == system
          ) self.nixosConfigurations
        );

    # Home-manager standalone configs (SteamOS) — buildable on x86_64-linux,
    # so CI proves the Steam package set still builds on every push.
    homeChecks = nixpkgs.lib.optionalAttrs (system == "x86_64-linux") (
      builtins.mapAttrs (_: cfg: cfg.activationPackage) self.homeConfigurations
    );
  in
  { inherit pre-commit-check; } // darwinChecks // nixosChecks // homeChecks
)
