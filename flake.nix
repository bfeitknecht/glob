{
  # The tools for this repository: `nix develop`, or direnv (`.envrc`).
  description = "glob: the blog (Typst)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
            }
          )
        );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [
            pkgs.typst
            pkgs.just
            pkgs.curl
            pkgs.unzip
            # fetch-fonts: OTF to WOFF2
            pkgs.woff2
          ];
        };
      });
      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
