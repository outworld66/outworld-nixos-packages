{
  description = "Reusable Nix packages for outworld NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    ferrite = {
      url = "github:OlaProeis/Ferrite/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      systems = [ "x86_64-linux" ];
      packageNames = builtins.filter (name: builtins.pathExists (./packages + "/${name}/default.nix")) (
        builtins.attrNames (builtins.readDir ./packages)
      );
    in
    {
      packages = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "kaspersky-ksc-agent";
          };
        in
        nixpkgs.lib.genAttrs packageNames (
          name: nixpkgs.lib.callPackageWith (pkgs // { inherit inputs; }) (./packages + "/${name}") { }
        )
      );
    };
}
