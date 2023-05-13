{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nci = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, fenix, crane, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
        inputs.nci.flakeModule
      ];
      systems = [ "x86_64-linux" ];

      perSystem = { config, self', inputs', lib, pkgs, system, ... }:
        let
          crateName = "simple-binary";
          crateOutputs = config.nci.outputs.${crateName};

          fenixStable = fenix.packages.${system}.stable;
          rustToolchain = fenixStable.withComponents [
            "rustc"
            "cargo"
            "clippy"
            "rust-src"
            "rust-docs"
            "rust-analyzer"
            "llvm-tools-preview"
          ];
        in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          nci.toolchains.build = rustToolchain;
          nci.projects.${crateName}.relPath = "";
          nci.crates.${crateName}.export = true;

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages.default = crateOutputs.packages.release;

          devenv.shells.default = {
            name = crateName;

            # https://devenv.sh/reference/options/
            packages = with config; with pkgs; [
              git
              hello
              clang
              mold
            ] ++ [
              rustToolchain
            ];

            enterShell = ''
              hello
            '';
          };

        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
