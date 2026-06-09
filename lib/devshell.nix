{
  self,
  nixpkgs,
  systems,
}:
nixpkgs.lib.genAttrs systems (
  system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
  in
  {
    default = pkgs.mkShell {
      inherit shellHook;
      packages = enabledPackages ++ [
        pkgs.sops
        pkgs.ssh-to-age
      ];
    };
  }
)
