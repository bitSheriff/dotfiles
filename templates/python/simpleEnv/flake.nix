{
  description = "Python dev environment";

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

        # Define a Python environment for the build phase
        pythonEnv = pkgs.python3.withPackages (
          ps: with ps; [
            matplotlib
            numpy
            pandas
            scipy
            scikit-learn
          ]
        );

      in
      {

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pythonEnv
          ];

          shellHook = ''
            echo "Python devShell loaded!"
          '';
        };
      }
    );
}
