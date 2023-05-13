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

          # Use mold for linking.
          moldLinking = {
            add-env.RUSTFLAGS = "-C linker=${lib.getExe pkgs.clang} -C link-arg=-fuse-ld=${lib.getExe pkgs.mold}";
            add-inputs.overrideAttrs = old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                pkgs.clang
                pkgs.mold
              ];
            };
          };

          buildDeps = [
            # Add build dependencies here.
          ];

          nativeBuildDeps = [
            # Add native build dependencies here.
          ];

          runtimeDeps = [
            # Add runtime dependencies here.
          ];

          # Inputs for building the dependencies of the crate.
          crateDepsInputOverrides = old: {
            buildInputs = (old.buildInputs or [ ]) ++ buildDeps ++ [
              # Add dependency specific build dependencies here.
            ];
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ nativeBuildDeps ++ [
              # Add dependency specific native build dependencies here.
            ];
          };

          # Inputs for building the crate itself.
          crateInputOverrides = old: {
            buildInputs = (old.buildInputs or [ ]) ++ buildDeps ++ [
              # Add crate specific build dependencies here.
            ];
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ nativeBuildDeps ++ [
              # Add crate specific native build dependencies here.
            ];
          };
        in
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          nci.toolchains.build = rustToolchain;
          # Projectwise settings.
          nci.projects.${project} = {
            relPath = "";
            depsOverrides = moldLinking // {
              inherit stdenv;
            };
            overrides = moldLinking // {
              inherit stdenv;
            };
          };
          # Crate settings.
          nci.crates.${crateName} = {
            export = true;
            runtimeLibs = runtimeDeps;
            depsOverrides = {
              add-inputs.overrideAttrs = crateDepsInputOverrides;
            };
            overrides = {
              add-inputs.overrideAttrs = crateInputOverrides;
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
