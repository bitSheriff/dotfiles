# overlays/default.nix
inputs: final: prev: {
  # Signal TUI client
  siggy = final.callPackage ./siggy.nix { };

  # git-today recaps your daily git work
  git-today = inputs.git-today.packages.${final.stdenv.hostPlatform.system}.default;

  # supernote-tool for Ratta Supernote
  supernote-tool = final.python3Packages.callPackage ./supernote-tool.nix { };
}

