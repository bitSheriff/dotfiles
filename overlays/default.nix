# overlays/default.nix
final: prev: {
  # Signal TUI client
  siggy = final.callPackage ./siggy.nix { };

  # git-today recaps your daily git work
  git-today = final.callPackage ./git-today.nix { };
}
