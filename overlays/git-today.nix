{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "git-today";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "bitSheriff";
    repo = "git-today";
    rev = "v${version}";
    hash = "sha256-jvXhIGyqlQjgZN/Gx/2vsvk1U3SDpypn0mBYumNCOow=";
  };

  cargoHash = "sha256-cnGyig8X9OgWFHR9pCIl4NdfjmGTQLWsXoNxEa92H50=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "A tool to recap your daily git work";
    homepage = "https://github.com/bitSheriff/git-today";
    license = licenses.mit;
  };
}
