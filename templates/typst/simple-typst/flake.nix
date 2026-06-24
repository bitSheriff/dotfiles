{
  description = "A simple Typst project environment and build system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      typix,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs) lib;
        pkgs = nixpkgs.legacyPackages.${system};
        typixLib = typix.lib.${system};

        src = lib.cleanSourceWith {
          src = ./.;
          filter =
            path: type:
            let
              baseName = baseNameOf path;
            in
            (lib.hasSuffix ".typ" baseName)
            || (lib.hasInfix "/resources/" path)
            || (lib.any (suffix: lib.hasSuffix suffix baseName) [
              ".svg"
              ".png"
              ".jpg"
              ".jpeg"
            ])
            || (type == "directory");
        };

        commonArgs = {
          typstSource = "main.typ";
          fontPaths = [ ];
          virtualPaths = [ ];
        };

        unstable_typstPackages = [
          {
            name = "colorful-boxes";
            version = "1.4.3";
            hash = "sha256-CTBHlkrNbNg+w1FK7xdickxBBgK/9BgC6maZoUQR5BU=";
          }
          {
            name = "showybox";
            version = "2.0.3";
            hash = "sha256-VQacq1Xi2bnY5Fh4hm0PVBZVXpuxYcn/76Fg/rOprY0=";
          }
          {
            name = "finite";
            version = "0.5.0";
            hash = "sha256-MccfK+c696n3Wz13uxt70gr4T0CHrDYSrM/5LburgDc=";
          }
          {
            name = "t4t";
            version = "0.4.3";
            hash = "sha256-xQDGfFTLPHeRKIwr1032nYsAl83JA+9IometWpPcN0k=";
          }
          {
            name = "cetz";
            version = "0.3.4";
            hash = "sha256-5w3UYRUSdi4hCvAjrp9HslzrUw7BhgDdeCiDRHGvqd4=";
          }
          {
            name = "oxifmt";
            version = "0.2.1";
            hash = "sha256-8PNPa9TGFybMZ1uuJwb5ET0WGIInmIgg8h24BmdfxlU=";
          }
          {
            name = "cheq";
            version = "0.3.0";
            hash = "sha256-ogwwK2kYnsLdYKTvq8rYSLry52QqneeCVE+TX1TSJjo=";
          }
          {
            name = "drafting";
            version = "0.2.2";
            hash = "sha256-CG6H7XWyzOMFbuOs93AWDZZ9bX08I0oQ64/VR/aJZ5g=";
          }
        ];

        build-drv = typixLib.buildTypstProject (commonArgs // { inherit src unstable_typstPackages; });
        build-script = typixLib.buildTypstProjectLocal (
          commonArgs // { inherit src unstable_typstPackages; }
        );

        watch-script = typixLib.watchTypstProject commonArgs;

      in
      {
        packages.default = build-drv;

        apps = rec {
          default = watch;
          build = flake-utils.lib.mkApp { drv = build-script; };
          watch = flake-utils.lib.mkApp { drv = watch-script; };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Typst Stuff
            typst
            tinymist

            # own scripts
            watch-script
          ];
        };
      }
    );
}
