{
  self,
  nixpkgs,
}:
let
  systems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "x86_64-linux"
  ];
in
nixpkgs.lib.genAttrs systems (
  system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
  in
  {
    default = pkgs.mkShell {
      inherit shellHook;
      buildInputs = enabledPackages ++ [
        pkgs.sops
        pkgs.ssh-to-age
      ];
    };
  }
)
