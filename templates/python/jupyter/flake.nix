{
  description = "Python dev environment with uv and jupyter";

  inputs = {
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Define the Jupyter runner as a proper Nix package
        runJupyter = pkgs.writeShellScriptBin "run_jupyter" ''
          exec ${pkgs.uv}/bin/uv run --with jupyter jupyter lab
        '';

        # Define the submission package with a minimal installPhase
        submitPkg = pkgs.stdenv.mkDerivation {
          pname = "code-submission";
          version = "0.1.0";
          src = ./.;

          installPhase = ''
            mkdir -p $out
            cp -r . $out/
          '';
        };
      in
      {

        packages = {
          default = submitPkg;
          submit = submitPkg;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            uv
            python3
            runJupyter
          ];

          shellHook = ''
            echo "Python devShell loaded!"
          '';
        };
      }
    );
}
