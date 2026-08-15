# overlays/default.nix
inputs: final: prev: {
  # Signal TUI client
  siggy = final.callPackage ./siggy.nix { };

  # git-today recaps your daily git work
  git-today = inputs.git-today.packages.${final.stdenv.hostPlatform.system}.default;

  # supernote-tool for Ratta Supernote
  supernote-tool = final.python3Packages.callPackage ./supernote-tool.nix { };

  # marktext markdown editor. nixpkgs tracks the develop branch but lags far
  # behind (snapshot 2025-11-19), and there is no recent stable release. Pin to
  # the upstream v0.20.0-rc.1 prebuilt AppImage instead. Bump url+hash in
  # ./marktext.nix to update; see its `version`.
  marktext = final.callPackage ./marktext.nix { };

  # LSP server for hledger journal files, not (yet) in nixpkgs
  hledger-lsp = final.callPackage ./hledger-lsp.nix { };

}
