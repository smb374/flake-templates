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

  outputs = inputs@{ flake-parts, fenix, ... }:
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

          project = crateName;
          binary = crateName;

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

          stdenv = {
            # in this case we will set it to the clang stdenv
            override = old: { stdenv = pkgs.clangStdenv; };
          };
        in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          nci.toolchains.build = rustToolchain;
          nci.projects.${project} = {
            relPath = "";
            depsOverrides = {
              inherit stdenv;
              add-env.RUSTFLAGS = "-C linker=${lib.getExe pkgs.clang} -C link-arg=-fuse-ld=${lib.getExe pkgs.mold}";
              add-inputs.overrideAttrs = old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  # Use mold for linking.
                  pkgs.clang
                  pkgs.mold
                ];
              };
            };
            overrides = {
              inherit stdenv;
              add-env.RUSTFLAGS = "-C linker=${lib.getExe pkgs.clang} -C link-arg=-fuse-ld=${lib.getExe pkgs.mold}";
              add-inputs.overrideAttrs = old: {
                buildInputs = (old.buildInputs or [ ]) ++ [
                  # Add other buildInputs below...
                ];
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  # Use mold for linking.
                  pkgs.clang
                  pkgs.mold
                  # Add other nativeBuildInputs below...
                ];
              };
            };
          };
          nci.crates.${crateName} = {
            export = true;
            overrides = {
              add-inputs.overrideAttrs = old: {
                buildInputs = (old.buildInputs or [ ]) ++ [
                  # Add other build inputs here.
                ];
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  # Add other native build inputs here.
                ];
              };
            };
          };

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages.default = crateOutputs.packages.release;

          apps.default = {
            program = "${config.packages.default}/bin/${binary}";
          };

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
