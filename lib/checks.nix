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
        nixfmt-rfc-style.enable = true;
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
  in
  { inherit pre-commit-check; } // darwinChecks // nixosChecks
)
