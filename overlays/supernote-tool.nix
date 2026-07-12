{
  lib,
  buildPythonApplication,
  buildPythonPackage,
  fetchFromGitHub,
  fetchPypi,
  hatchling,
  colour,
  fusepy,
  numpy,
  pillow,
  pypng,
  reportlab,
  svglib,
  svgwrite,
}:

let
  potracer = buildPythonPackage rec {
    pname = "potracer";
    version = "0.0.4";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-MsvbmERGBmvPvotgAUKlS5D6baJ0tpIZRzIF1uTAlxM=";
    };

    propagatedBuildInputs = [
      numpy
    ];

    doCheck = false;

    meta = with lib; {
      description = "A pure-Python port of the Potrace library";
      homepage = "https://github.com/tatarize/potrace";
      license = licenses.gpl2Plus;
    };
  };
in
buildPythonApplication rec {
  pname = "supernote-tool";
  version = "0.7.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jya-dev";
    repo = "supernote-tool";
    rev = "v${version}";
    hash = "sha256-rB6kOJDWvxXaXGiTDI8/+hJDtqCssRUAZ5uNCJM+3aw=";
  };

  nativeBuildInputs = [
    hatchling
  ];

  propagatedBuildInputs = [
    colour
    fusepy
    numpy
    pillow
    potracer
    pypng
    reportlab
    svglib
    svgwrite
  ];

  doCheck = false;

  meta = with lib; {
    description = "An unofficial python tool for Ratta Supernote";
    homepage = "https://github.com/jya-dev/supernote-tool";
    license = licenses.asl20;
    mainProgram = "supernote-tool";
  };
}
