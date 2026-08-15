{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "hledger-lsp";
  version = "0.2.55";

  src = fetchFromGitHub {
    owner = "juev";
    repo = "hledger-lsp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BkvZKCUtI+HOSkWS5jua48LIGD9goda50F3b8HP3y7s=";
  };

  vendorHash = "sha256-imF6wCMC+5J94TQjZU0SXOwlw5SR/EB60GeYVS3O/iA=";

  subPackages = [ "cmd/hledger-lsp" ];

  # Mirrors .goreleaser.yaml: the binary reports these via `hledger-lsp --version`.
  # Commit/Date are left at their "unknown" defaults to keep the build reproducible.
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
  ];

  meta = {
    description = "Language Server Protocol implementation for hledger journal files";
    homepage = "https://github.com/juev/hledger-lsp";
    license = lib.licenses.mit;
    mainProgram = "hledger-lsp";
    platforms = lib.platforms.unix;
  };
})
