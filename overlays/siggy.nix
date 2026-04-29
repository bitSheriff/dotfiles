{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "siggy";
  version = "1.7.1";

  # https://github.com/johnsideserf/siggy
  src = fetchFromGitHub {
    owner = "johnsideserf";
    repo = "siggy";
    rev = "v${version}";
    hash = "sha256-C2jwSO/DyHTSp0Czjj01sjMiJqxHHmWbeoxhM1XnmNI=";
  };

  cargoHash = "sha256-fbAULOPhGDfYCOYx2+6Zi68rWoXxz1fOWxhXUtaMeJM=";

  meta = with lib; {
    description = "Terminal-based Signal messenger client with vim keybindings";
    homepage = "https://github.com/johnsideserf/siggy";
    license = licenses.mit;
  };
}
