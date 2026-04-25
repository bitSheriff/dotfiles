# overlays/default.nix
final: prev: {
  # Signal TUI client
  siggy = final.callPackage ./siggy.nix { };
}
